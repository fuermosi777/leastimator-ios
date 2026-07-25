//
//  VehicleEntityTests.swift
//  LeastimatorTests
//
//  Created by Hao on 7/25/26.
//

import XCTest
import CoreData
@testable import Leastimator

/// Covers the identifier round trip that both the widget configuration and the
/// Shortcuts intents depend on. A broken resolve means a configured widget silently
/// falls back to the wrong vehicle, which is hard to notice and easy to ship.
@available(iOS 17.0, *)
final class VehicleEntityTests: XCTestCase {

  private var container: NSPersistentContainer!
  private var context: NSManagedObjectContext { container.viewContext }

  override func setUpWithError() throws {
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

  @discardableResult
  private func makeVehicle(name: String, removed: Bool = false) -> Vehicle {
    let vehicle = Vehicle(context: context)
    vehicle.name = name
    vehicle.starting = 10_000
    vehicle.allowed = 30_000
    vehicle.lengthOfLease = 36
    vehicle.startDate = Date().addingTimeInterval(-90 * 24 * 60 * 60)
    vehicle.lengthUnit = LengthUnit.Imperial.rawValue
    vehicle.removed = removed
    return vehicle
  }

  func testResolvesSavedVehicleFromIdentifier() throws {
    let vehicle = makeVehicle(name: "Model 3")
    try context.save()

    let entity = try XCTUnwrap(VehicleEntity(vehicle: vehicle))
    XCTAssertEqual(entity.name, "Model 3")

    let resolved = VehicleEntity.resolveVehicle(id: entity.id, in: context)
    XCTAssertEqual(resolved, vehicle)
  }

  func testDoesNotVendEntityForUnsavedVehicle() {
    // A temporary object ID would not survive a relaunch, leaving a widget pointing
    // at nothing.
    let vehicle = makeVehicle(name: "Unsaved")
    XCTAssertTrue(vehicle.objectID.isTemporaryID)
    XCTAssertNil(VehicleEntity(vehicle: vehicle))
  }

  func testResolveReturnsNilForRemovedVehicle() throws {
    let vehicle = makeVehicle(name: "Trashed")
    try context.save()
    let entity = try XCTUnwrap(VehicleEntity(vehicle: vehicle))

    vehicle.removed = true
    try context.save()

    XCTAssertNil(VehicleEntity.resolveVehicle(id: entity.id, in: context),
                 "A trashed vehicle must not keep driving a widget")
  }

  func testResolveReturnsNilForGarbageIdentifier() {
    XCTAssertNil(VehicleEntity.resolveVehicle(id: "not-a-url", in: context))
    XCTAssertNil(VehicleEntity.resolveVehicle(id: "x-coredata://nonexistent/Vehicle/p999",
                                              in: context))
  }

  func testNameFallsBackWhenUnnamed() throws {
    let vehicle = makeVehicle(name: "Temp")
    vehicle.name = nil
    try context.save()

    let entity = try XCTUnwrap(VehicleEntity(vehicle: vehicle))
    XCTAssertEqual(entity.name, "Vehicle")
  }
}
