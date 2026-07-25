//
//  OdoReadingWriterTests.swift
//  LeastimatorTests
//
//  Created by Hao on 7/25/26.
//

import XCTest
import CoreData
@testable import Leastimator

final class OdoReadingWriterTests: XCTestCase {

  private var container: NSPersistentContainer!
  private var context: NSManagedObjectContext { container.viewContext }

  override func setUpWithError() throws {
    // In-memory store so tests never touch the app group / CloudKit store.
    container = NSPersistentContainer(name: "Leastimator")
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]

    var loadError: Error?
    container.loadPersistentStores { _, error in loadError = error }
    if let loadError { throw loadError }
  }

  override func tearDownWithError() throws {
    container = nil
  }

  // MARK: - Helpers

  private func makeVehicle(starting: Int64 = 10_000,
                           lengthUnit: Int16 = LengthUnit.Imperial.rawValue) -> Vehicle {
    let vehicle = Vehicle(context: context)
    vehicle.name = "Test Car"
    vehicle.starting = starting
    vehicle.allowed = 30_000
    vehicle.lengthOfLease = 36
    vehicle.startDate = Date().addingTimeInterval(-90 * 24 * 60 * 60)
    vehicle.lengthUnit = lengthUnit
    return vehicle
  }

  @discardableResult
  private func addReading(_ value: Int64, daysAgo: Int, to vehicle: Vehicle) -> OdoReading {
    let reading = OdoReading(context: context)
    reading.value = value
    reading.date = Date().addingTimeInterval(TimeInterval(-daysAgo * 24 * 60 * 60))
    reading.vehicle = vehicle
    return reading
  }

  private func assertThrows<T>(_ expression: @autoclosure () throws -> T,
                               _ check: (AppError) -> Bool,
                               file: StaticString = #filePath,
                               line: UInt = #line) {
    do {
      _ = try expression()
      XCTFail("Expected an error but none was thrown", file: file, line: line)
    } catch let error as AppError {
      XCTAssertTrue(check(error), "Unexpected AppError case: \(error)", file: file, line: line)
    } catch {
      XCTFail("Expected AppError, got \(error)", file: file, line: line)
    }
  }

  // MARK: - Creating readings

  func testSavesValidReading() throws {
    let vehicle = makeVehicle()
    addReading(12_000, daysAgo: 10, to: vehicle)
    try context.save()

    let reading = try OdoReadingWriter.save(value: 12_500,
                                            date: Date(),
                                            vehicle: vehicle,
                                            in: context)

    XCTAssertEqual(reading.value, 12_500)
    XCTAssertEqual(reading.vehicle, vehicle)
    XCTAssertEqual(vehicle.latestReading?.value, 12_500)
  }

  func testRejectsReadingBelowStartingMileage() throws {
    let vehicle = makeVehicle(starting: 10_000)
    try context.save()

    assertThrows(try OdoReadingWriter.save(value: 9_999,
                                           date: Date(),
                                           vehicle: vehicle,
                                           in: context)) { error in
      if case .invalidInput = error { return true }
      return false
    }
  }

  /// The rule that previously only existed as a disabled button in the UI.
  func testRejectsReadingBelowLatest() throws {
    let vehicle = makeVehicle()
    addReading(12_400, daysAgo: 5, to: vehicle)
    try context.save()

    assertThrows(try OdoReadingWriter.save(value: 12_000,
                                           date: Date(),
                                           vehicle: vehicle,
                                           in: context)) { error in
      if case .readingBelowLatest(let latest, let unit) = error {
        return latest == 12_400 && unit == "mi"
      }
      return false
    }

    XCTAssertEqual(vehicle.sortedReadings.count, 1, "Rejected reading must not be persisted")
  }

  func testAllowsReadingEqualToLatest() throws {
    let vehicle = makeVehicle()
    addReading(12_400, daysAgo: 5, to: vehicle)
    try context.save()

    XCTAssertNoThrow(try OdoReadingWriter.save(value: 12_400,
                                               date: Date(),
                                               vehicle: vehicle,
                                               in: context))
    XCTAssertEqual(vehicle.sortedReadings.count, 2)
  }

  func testBelowLatestErrorUsesVehicleUnit() throws {
    let vehicle = makeVehicle(lengthUnit: LengthUnit.Metric.rawValue)
    addReading(20_000, daysAgo: 5, to: vehicle)
    try context.save()

    assertThrows(try OdoReadingWriter.save(value: 19_000,
                                           date: Date(),
                                           vehicle: vehicle,
                                           in: context)) { error in
      if case .readingBelowLatest(_, let unit) = error { return unit == "km" }
      return false
    }
  }

  // MARK: - Editing readings

  /// Editing has always been allowed to move a reading downward; the intent-driven
  /// refactor must not silently tighten that.
  func testEditingAllowsValueBelowLatest() throws {
    let vehicle = makeVehicle()
    let older = addReading(12_000, daysAgo: 10, to: vehicle)
    addReading(12_400, daysAgo: 5, to: vehicle)
    try context.save()

    XCTAssertNoThrow(try OdoReadingWriter.save(value: 11_500,
                                               date: older.date ?? Date(),
                                               vehicle: vehicle,
                                               editing: older,
                                               in: context))
    XCTAssertEqual(older.value, 11_500)
  }

  func testEditingStillEnforcesStartingMileage() throws {
    let vehicle = makeVehicle(starting: 10_000)
    let reading = addReading(12_000, daysAgo: 10, to: vehicle)
    try context.save()

    assertThrows(try OdoReadingWriter.save(value: 500,
                                           date: Date(),
                                           vehicle: vehicle,
                                           editing: reading,
                                           in: context)) { error in
      if case .invalidInput = error { return true }
      return false
    }
  }

  func testEditingDoesNotReparentReading() throws {
    let vehicle = makeVehicle()
    let other = makeVehicle()
    let reading = addReading(12_000, daysAgo: 10, to: other)
    try context.save()

    try OdoReadingWriter.save(value: 12_100,
                              date: Date(),
                              vehicle: vehicle,
                              editing: reading,
                              in: context)

    XCTAssertEqual(reading.vehicle, other, "Editing must not move a reading between vehicles")
  }

  // MARK: - Vehicle helpers

  func testSortedReadingsAreOldestFirst() throws {
    let vehicle = makeVehicle()
    addReading(12_400, daysAgo: 1, to: vehicle)
    addReading(12_000, daysAgo: 10, to: vehicle)
    addReading(12_200, daysAgo: 5, to: vehicle)
    try context.save()

    XCTAssertEqual(vehicle.sortedReadings.map(\.value), [12_000, 12_200, 12_400])
    XCTAssertEqual(vehicle.latestReading?.value, 12_400)
  }

  func testMinimumNextReadingValueFallsBackToStartingMileage() throws {
    let vehicle = makeVehicle(starting: 10_000)
    try context.save()

    XCTAssertNil(vehicle.latestReading)
    XCTAssertEqual(vehicle.minimumNextReadingValue, 10_000)
  }
}
