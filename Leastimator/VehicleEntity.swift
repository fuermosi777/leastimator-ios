//
//  VehicleEntity.swift
//  Leastimator
//
//  Created by Hao on 7/25/26.
//

import AppIntents
import CoreData

/// A vehicle as the system sees it — used by the widget's configuration intent to pick
/// which car a widget shows, and by the Shortcuts/Siri intents to pick which car a
/// reading belongs to.
///
/// The identifier is the Core Data object URI, the same scheme `Vehicle+Extensions`
/// already uses for its per-vehicle UserDefaults keys.
@available(iOS 17.0, *)
struct VehicleEntity: AppEntity, Identifiable {
  let id: String
  let name: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Vehicle")
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

  static var defaultQuery = VehicleEntityQuery()
}

@available(iOS 17.0, *)
extension VehicleEntity {
  /// Only vehicles that have actually been saved get an identifier that survives a
  /// relaunch — a temporary object ID would leave a widget pointing at nothing.
  init?(vehicle: Vehicle) {
    guard !vehicle.objectID.isTemporaryID else { return nil }
    self.id = vehicle.objectID.uriRepresentation().absoluteString
    self.name = vehicle.name ?? "Vehicle"
  }

  /// Resolves an entity identifier back to a live managed object.
  ///
  /// Returns nil when the vehicle has been deleted or the URI no longer maps to
  /// anything, so callers can fall back to a placeholder instead of crashing.
  static func resolveVehicle(id: String, in context: NSManagedObjectContext) -> Vehicle? {
    // `managedObjectID(forURIRepresentation:)` raises an ObjC exception — not a Swift
    // error — for anything that isn't a Core Data URI, which would take the whole
    // widget extension down. Screen the URL before handing it over.
    guard let url = URL(string: id),
          url.scheme == "x-coredata",
          let coordinator = context.persistentStoreCoordinator,
          let objectID = coordinator.managedObjectID(forURIRepresentation: url) else {
      return nil
    }

    guard let vehicle = try? context.existingObject(with: objectID) as? Vehicle else {
      return nil
    }

    // A vehicle the user moved to the trash should not keep driving a widget.
    return vehicle.removed ? nil : vehicle
  }
}

// MARK: - Query

@available(iOS 17.0, *)
struct VehicleEntityQuery: EntityQuery {
  /// Active vehicles, matching what the app itself considers selectable.
  private static let activePredicate = NSPredicate(format: "removed == nil OR removed == false")

  @MainActor
  private func fetchActiveVehicles() -> [Vehicle] {
    let context = PersistenceController.shared.container.viewContext
    let request = Vehicle.fetchRequest()
    request.predicate = Self.activePredicate
    return (try? context.fetch(request)) ?? []
  }

  @MainActor
  func entities(for identifiers: [String]) async throws -> [VehicleEntity] {
    let context = PersistenceController.shared.container.viewContext
    return identifiers.compactMap { id in
      guard let vehicle = VehicleEntity.resolveVehicle(id: id, in: context) else { return nil }
      return VehicleEntity(vehicle: vehicle)
    }
  }

  @MainActor
  func suggestedEntities() async throws -> [VehicleEntity] {
    fetchActiveVehicles().compactMap { VehicleEntity(vehicle: $0) }
  }

  @MainActor
  func defaultResult() async -> VehicleEntity? {
    // Prefer the car already flagged for the widget, then the one the app opens to,
    // so a freshly added widget shows something sensible before it is configured.
    let vehicles = fetchActiveVehicles()
    let preferred = vehicles.first(where: { $0.showOnWidget })
      ?? vehicles.first(where: { $0.showOnStart })
      ?? vehicles.first
    return preferred.flatMap { VehicleEntity(vehicle: $0) }
  }
}
