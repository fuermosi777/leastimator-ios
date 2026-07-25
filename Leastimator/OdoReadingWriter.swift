//
//  OdoReadingWriter.swift
//  Leastimator
//
//  Created by Hao on 7/25/26.
//

import CoreData
import WidgetKit

/// Single place where manually entered odometer readings are validated and written.
///
/// Before this existed the validation lived in `EditReadingView`: the "not below the
/// latest reading" rule was only enforced by disabling the save button, so any caller
/// that wasn't that view (an App Intent, for instance) could write a reading that went
/// backwards and skew every projection. Keeping the rules here means the UI and Siri
/// can't drift apart.
///
/// The Tesla sync and CSV import paths intentionally do *not* go through this — they
/// have their own dedupe rules (`TeslaSyncService.shouldAddReading`, day/value pairs)
/// that are a poor fit for a person typing in a number.
enum OdoReadingWriter {

  /// Validates `value` for `vehicle` without writing anything.
  ///
  /// - Parameter existingReading: the reading being edited, if any. Edits skip the
  ///   monotonicity check, matching the behavior the app has always had — you're
  ///   allowed to correct a historical reading downward.
  static func validate(value: Int,
                       for vehicle: Vehicle,
                       editing existingReading: OdoReading? = nil) throws {
    guard value >= Int(vehicle.starting) else {
      throw AppError.invalidInput(reason: "Odometer reading less than the starting mileage of this vehicle")
    }

    // Only new readings have to move forward.
    guard existingReading == nil else { return }

    if let latest = vehicle.latestReading, value < Int(latest.value) {
      throw AppError.readingBelowLatest(latest: Int(latest.value),
                                        unit: vehicle.lengthUnitShortForm)
    }
  }

  /// Validates and saves a reading, then refreshes the app UI and widget timelines.
  ///
  /// Passing `existingReading` updates that reading in place instead of inserting.
  @discardableResult
  static func save(value: Int,
                   date: Date,
                   vehicle: Vehicle,
                   editing existingReading: OdoReading? = nil,
                   in context: NSManagedObjectContext) throws -> OdoReading {
    try validate(value: value, for: vehicle, editing: existingReading)

    let reading = existingReading ?? OdoReading(context: context)
    reading.date = date
    reading.value = Int64(value)

    // The relationship is only set on insert; editing must not re-parent a reading.
    if existingReading == nil {
      reading.vehicle = vehicle
    }

    do {
      try context.save()
    } catch {
      context.rollback()
      throw AppError.failedContextSave
    }

    context.refresh(vehicle, mergeChanges: true)
    vehicle.objectWillChange.send()
    WidgetCenter.shared.reloadAllTimelines()

    return reading
  }
}
