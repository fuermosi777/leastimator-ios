//
//  OdometerIntents.swift
//  Leastimator
//
//  Created by Hao on 7/25/26.
//

import AppIntents
import CoreData
import WidgetKit

// MARK: - Logging a reading

/// Records an odometer reading without opening the app — via Siri, a Shortcuts
/// automation, an NFC tag in the car, or a button on a widget.
///
/// Validation runs through `OdoReadingWriter`, the same path the in-app editor uses,
/// so a reading logged by voice can never be one the app itself would reject.
@available(iOS 17.0, *)
struct AddOdometerReadingIntent: AppIntent {
  static var title: LocalizedStringResource = "Log Odometer Reading"
  static var description = IntentDescription("Records a new odometer reading for a vehicle.")

  /// Writing happens on the view context, matching every other write in the app.
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Vehicle")
  var vehicle: VehicleEntity

  @Parameter(title: "Reading")
  var value: Int

  init() {}

  init(vehicle: VehicleEntity, value: Int) {
    self.vehicle = vehicle
    self.value = value
  }

  static var parameterSummary: some ParameterSummary {
    Summary("Log \(\.$value) on \(\.$vehicle)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let context = PersistenceController.shared.container.viewContext

    guard let managedVehicle = VehicleEntity.resolveVehicle(id: vehicle.id, in: context) else {
      throw AppError.vehicleNotFound
    }

    try OdoReadingWriter.save(value: value,
                              date: Date(),
                              vehicle: managedVehicle,
                              in: context)

    Logger.shared.readingLoggedViaIntent()

    // Report where the reading leaves them, not just that it saved — the projection
    // is the reason to log at all.
    let info = Compute(managedVehicle)
    let unit = managedVehicle.lengthUnitShortForm
    let variance = info.mileageVariance ?? 0
    let dialog: IntentDialog

    if variance > 0 {
      dialog = IntentDialog("Logged \(value) \(unit). You're projected to finish \(variance) \(unit) over your limit.")
    } else {
      dialog = IntentDialog("Logged \(value) \(unit). You're projected to finish \(abs(variance)) \(unit) under your limit.")
    }

    return .result(dialog: dialog)
  }
}

// MARK: - Reading the current status

@available(iOS 17.0, *)
struct GetMileageStatusIntent: AppIntent {
  static var title: LocalizedStringResource = "Get Mileage Status"
  static var description = IntentDescription("Reports projected mileage and how it compares to your lease limit.")

  static var openAppWhenRun: Bool = false

  @Parameter(title: "Vehicle")
  var vehicle: VehicleEntity

  init() {}

  init(vehicle: VehicleEntity) {
    self.vehicle = vehicle
  }

  static var parameterSummary: some ParameterSummary {
    Summary("Get mileage status for \(\.$vehicle)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
    let context = PersistenceController.shared.container.viewContext

    guard let managedVehicle = VehicleEntity.resolveVehicle(id: vehicle.id, in: context) else {
      throw AppError.vehicleNotFound
    }

    let info = Compute(managedVehicle)
    let unit = managedVehicle.lengthUnitShortForm
    let variance = info.mileageVariance ?? 0
    let comparison = variance > 0
      ? "\(variance) \(unit) over your limit"
      : "\(abs(variance)) \(unit) under your limit"

    return .result(
      value: info.normalPredicatedMileage,
      dialog: IntentDialog("\(managedVehicle.name ?? "Your vehicle") is projected to reach \(info.normalPredicatedMileage) \(unit) by lease end, \(comparison).")
    )
  }
}

// MARK: - Shortcuts

/// Makes the phrases work the moment the app is installed, with no setup, and puts
/// them in Spotlight.
@available(iOS 17.0, *)
struct LeastimatorShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddOdometerReadingIntent(),
      phrases: [
        "Log odometer in \(.applicationName)",
        "Record mileage in \(.applicationName)",
        "Add a reading to \(.applicationName)"
      ],
      shortTitle: "Log Reading",
      systemImageName: "gauge.with.dots.needle.bottom.50percent"
    )

    AppShortcut(
      intent: GetMileageStatusIntent(),
      phrases: [
        "Check my lease mileage in \(.applicationName)",
        "How's my mileage in \(.applicationName)"
      ],
      shortTitle: "Mileage Status",
      systemImageName: "chart.line.uptrend.xyaxis"
    )
  }
}
