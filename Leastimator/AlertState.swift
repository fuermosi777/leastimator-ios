//
//  AlertState.swift
//  Leastimator
//
//  Created by Hao on 8/5/26.
//

import Foundation

enum PaceZone: String, Codable {
  case under, approaching, over
}

struct VehicleAlertState: Codable {
  var zone: PaceZone
  var lastTriggeredAt: Date
  var crossed90: Bool = false
  var crossed100: Bool = false
  var lastStaleNotifiedAt: Date? = nil
}

struct ActiveVehicleAlert: Codable {
  let kind: String
  let message: String
  let isGoodNews: Bool
}

/// Per-vehicle pace alert state, shared with the widget/extension via the App Group
/// so it never needs to sync through Core Data/CloudKit (which would cause repeat
/// notifications across a user's devices).
enum AlertStateStore {
  private static let suiteName = "group.im.liuhao.leastimator"
  private static var defaults: UserDefaults {
    UserDefaults(suiteName: suiteName) ?? .standard
  }

  private static func stateKey(for vehicleID: String) -> String {
    "lastAlertState.\(vehicleID)"
  }

  private static func activeAlertKey(for vehicleID: String) -> String {
    "activeAlert.\(vehicleID)"
  }

  static func state(for vehicleID: String) -> VehicleAlertState? {
    guard let data = defaults.data(forKey: stateKey(for: vehicleID)) else { return nil }
    return try? JSONDecoder().decode(VehicleAlertState.self, from: data)
  }

  static func setState(_ state: VehicleAlertState, for vehicleID: String) {
    guard let data = try? JSONEncoder().encode(state) else { return }
    defaults.set(data, forKey: stateKey(for: vehicleID))
  }

  static func activeAlert(for vehicleID: String) -> ActiveVehicleAlert? {
    guard let data = defaults.data(forKey: activeAlertKey(for: vehicleID)) else { return nil }
    return try? JSONDecoder().decode(ActiveVehicleAlert.self, from: data)
  }

  static func setActiveAlert(_ alert: ActiveVehicleAlert?, for vehicleID: String) {
    guard let alert else {
      defaults.removeObject(forKey: activeAlertKey(for: vehicleID))
      return
    }
    guard let data = try? JSONEncoder().encode(alert) else { return }
    defaults.set(data, forKey: activeAlertKey(for: vehicleID))
  }
}
