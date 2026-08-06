//
//  PaceAlertEngine.swift
//  Leastimator
//
//  Created by Hao on 8/5/26.
//

import Foundation

enum PaceAlertType {
  case surge(recentPerDay: Double, historicalPerDay: Double, percentOver: Int, projectedExcess: Int)
  case easing(recentPerDay: Double, projectedUnder: Int)
  case threshold90
  case threshold100
  case stale(daysSinceLastReading: Int)
}

struct PaceAlert {
  let vehicle: Vehicle
  let type: PaceAlertType
  let title: String
  let body: String

  var isGoodNews: Bool {
    if case .easing = type { return true }
    return false
  }

  var kind: String {
    switch type {
    case .surge: return "surge"
    case .easing: return "easing"
    case .threshold90: return "threshold90"
    case .threshold100: return "threshold100"
    case .stale: return "stale"
    }
  }
}

enum PaceAlertEngine {
  static let surgeThresholdPercent = 25
  static let cooldownDays = 7
  static let minReadingsForPaceAlerts = 3
  static let minHistoryDaysForPaceAlerts = 30
  static let staleDefaultDays = 30

  static func evaluate(vehicle: Vehicle, now: Date = Date()) -> PaceAlert? {
    guard vehicle.allowed > 0 else { return nil }
    let vehicleID = vehicle.entityIdentifier

    let info = Compute(vehicle)
    let storedState = AlertStateStore.state(for: vehicleID)

    // Threshold crossings are independent of the cooldown: each fires at most once ever.
    if let thresholdAlert = evaluateThresholdCrossing(vehicle: vehicle, info: info, storedState: storedState) {
      return thresholdAlert
    }

    // Everything else below shares one 7-day cooldown clock per vehicle.
    if let storedState, now.timeIntervalSince(storedState.lastTriggeredAt) < Double(cooldownDays) * 86400 {
      return nil
    }

    if let staleAlert = evaluateStale(vehicle: vehicle, now: now) {
      return staleAlert
    }

    let readings = vehicle.sortedReadings
    guard readings.count >= minReadingsForPaceAlerts, info.usedDays >= minHistoryDaysForPaceAlerts else {
      return nil
    }

    let currentZone = zone(for: info, vehicle: vehicle)

    if let surgeAlert = evaluateSurge(vehicle: vehicle, info: info, readings: readings, storedState: storedState, currentZone: currentZone) {
      return surgeAlert
    }

    if let easingAlert = evaluateEasing(vehicle: vehicle, info: info, readings: readings, storedState: storedState, currentZone: currentZone) {
      return easingAlert
    }

    return nil
  }

  /// Same progress formula as `VehiclePresentation.progressPercentage`: projected mileage
  /// over the full allowance. >=100% is over, >=90% is approaching, else under.
  private static func zone(for info: ExtendedVehicleInfo, vehicle: Vehicle) -> PaceZone {
    let denominator = Double(vehicle.allowed + vehicle.starting)
    guard denominator > 0 else { return .under }
    let progress = Double(info.normalPredicatedMileage) / denominator
    if progress >= 1.0 { return .over }
    if progress >= 0.9 { return .approaching }
    return .under
  }

  // MARK: - Threshold crossings (90% / 100%, fire once ever)

  private static func evaluateThresholdCrossing(vehicle: Vehicle, info: ExtendedVehicleInfo, storedState: VehicleAlertState?) -> PaceAlert? {
    let denominator = Double(vehicle.allowed + vehicle.starting)
    guard denominator > 0 else { return nil }
    let progress = min(Double(info.normalPredicatedMileage) / denominator, 2.0)

    let crossed90 = storedState?.crossed90 ?? false
    let crossed100 = storedState?.crossed100 ?? false

    if progress >= 1.0 && !crossed100 {
      persistThresholdCrossing(vehicle: vehicle, crossed90: true, crossed100: true, storedState: storedState)
      return PaceAlert(
        vehicle: vehicle,
        type: .threshold100,
        title: NSLocalizedString("You've reached your mileage limit", comment: "Pace alert: 100% threshold crossed title"),
        body: NSLocalizedString("Your projected mileage has reached 100% of your lease allowance.", comment: "Pace alert: 100% threshold crossed body")
      )
    }

    if progress >= 0.9 && !crossed90 {
      persistThresholdCrossing(vehicle: vehicle, crossed90: true, crossed100: crossed100, storedState: storedState)
      return PaceAlert(
        vehicle: vehicle,
        type: .threshold90,
        title: NSLocalizedString("Approaching your mileage limit", comment: "Pace alert: 90% threshold crossed title"),
        body: NSLocalizedString("Your projected mileage has reached 90% of your lease allowance.", comment: "Pace alert: 90% threshold crossed body")
      )
    }

    return nil
  }

  private static func persistThresholdCrossing(vehicle: Vehicle, crossed90: Bool, crossed100: Bool, storedState: VehicleAlertState?) {
    let vehicleID = vehicle.entityIdentifier
    var state = storedState ?? VehicleAlertState(zone: .under, lastTriggeredAt: .distantPast)
    state.crossed90 = crossed90
    state.crossed100 = crossed100
    AlertStateStore.setState(state, for: vehicleID)
  }

  // MARK: - Stale data

  private static func evaluateStale(vehicle: Vehicle, now: Date) -> PaceAlert? {
    guard vehicle.teslaVehicleId == nil else { return nil } // auto-synced vehicles never go stale
    let vehicleID = vehicle.entityIdentifier
    guard let lastReadingDate = vehicle.latestReading?.date else { return nil }

    let daysSince = Int(now.timeIntervalSince(lastReadingDate) / 86400)
    guard daysSince >= staleDefaultDays else { return nil }

    let storedState = AlertStateStore.state(for: vehicleID)
    if let lastStaleNotifiedAt = storedState?.lastStaleNotifiedAt,
       now.timeIntervalSince(lastStaleNotifiedAt) < Double(cooldownDays) * 86400 {
      return nil
    }

    var state = storedState ?? VehicleAlertState(zone: .under, lastTriggeredAt: .distantPast)
    state.lastTriggeredAt = now
    state.lastStaleNotifiedAt = now
    AlertStateStore.setState(state, for: vehicleID)

    let format = NSLocalizedString("No new mileage reading in %lld days. Add one to keep your projection accurate.", comment: "Pace alert: stale data body")
    return PaceAlert(
      vehicle: vehicle,
      type: .stale(daysSinceLastReading: daysSince),
      title: NSLocalizedString("Haven't heard from you in a while", comment: "Pace alert: stale data title"),
      body: String(format: format, daysSince)
    )
  }

  // MARK: - Pace surge / easing (30-day recent window vs. all-time average)

  private static func recentPerDay(vehicle: Vehicle, readings: [OdoReading]) -> Double {
    let data = prepareHistoryChartData(veh: vehicle, readings: readings, range: .oneMonth)
    guard let first = data.actualPoints.first, let last = data.actualPoints.last else { return 0 }
    let days = max(last.date.timeIntervalSince(first.date) / 86400, 1)
    return max((last.value - first.value) / days, 0)
  }

  private static func evaluateSurge(vehicle: Vehicle, info: ExtendedVehicleInfo, readings: [OdoReading], storedState: VehicleAlertState?, currentZone: PaceZone) -> PaceAlert? {
    let previousZone = storedState?.zone ?? .under
    guard previousZone != .over, currentZone == .over else { return nil }

    let recent = recentPerDay(vehicle: vehicle, readings: readings)
    let historical = info.mileagePerDay
    guard historical > 0, recent > historical * (1.0 + Double(surgeThresholdPercent) / 100.0) else { return nil }

    let percentOver = Int(((recent - historical) / historical * 100).rounded())
    let projectedExcess = info.excessMileage ?? 0
    let unit = vehicle.lengthUnitShortForm

    persistZoneTransition(vehicle: vehicle, zone: .over, storedState: storedState)

    let format = NSLocalizedString("You've driven %lld %@ this month, %lld%% more than usual. At this pace, you'll exceed your limit by %lld %@.", comment: "Pace alert: surge body")
    return PaceAlert(
      vehicle: vehicle,
      type: .surge(recentPerDay: recent, historicalPerDay: historical, percentOver: percentOver, projectedExcess: projectedExcess),
      title: NSLocalizedString("Heads up — your pace picked up", comment: "Pace alert: surge title"),
      body: String(format: format, Int(recent * 30), unit, percentOver, projectedExcess, unit)
    )
  }

  private static func evaluateEasing(vehicle: Vehicle, info: ExtendedVehicleInfo, readings: [OdoReading], storedState: VehicleAlertState?, currentZone: PaceZone) -> PaceAlert? {
    let previousZone = storedState?.zone ?? .under
    guard previousZone == .approaching || previousZone == .over, currentZone == .under else { return nil }

    let recent = recentPerDay(vehicle: vehicle, readings: readings)
    let historical = info.mileagePerDay
    guard historical > 0, recent < historical * (1.0 - Double(surgeThresholdPercent) / 100.0) else { return nil }

    let projectedUnder = max(0, (vehicle.allowed + vehicle.starting) - Int64(info.normalPredicatedMileage))
    guard projectedUnder > 0 else { return nil }

    persistZoneTransition(vehicle: vehicle, zone: .under, storedState: storedState)

    let format = NSLocalizedString("Nice — your pace over the last 30 days has slowed down. You're now projected to come in %lld %@ under your limit.", comment: "Pace alert: easing body")
    return PaceAlert(
      vehicle: vehicle,
      type: .easing(recentPerDay: recent, projectedUnder: Int(projectedUnder)),
      title: NSLocalizedString("Nice pace — you've eased off", comment: "Pace alert: easing title"),
      body: String(format: format, Int(projectedUnder), vehicle.lengthUnitShortForm)
    )
  }

  private static func persistZoneTransition(vehicle: Vehicle, zone: PaceZone, storedState: VehicleAlertState?) {
    let vehicleID = vehicle.entityIdentifier
    var state = storedState ?? VehicleAlertState(zone: .under, lastTriggeredAt: .distantPast)
    state.zone = zone
    state.lastTriggeredAt = Date()
    AlertStateStore.setState(state, for: vehicleID)
  }
}
