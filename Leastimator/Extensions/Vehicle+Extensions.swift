//
//  Vehicle+Extensions.swift
//  Leastimator
//
//  Created by Hao on 1/1/26.
//

import Foundation

extension Vehicle {
  /// Readings that are still live (excluding ones pending deletion), oldest first.
  /// Matches the filtering `Compute(_:)` uses so every caller agrees on what counts.
  var sortedReadings: [OdoReading] {
    let all = (readings?.allObjects as? [OdoReading] ?? []).filter { !$0.isDeleted }
    return all.sorted { ($0.date ?? Date()).compare($1.date ?? Date()) == .orderedAscending }
  }

  /// The most recent reading by date, or nil if none have been recorded.
  var latestReading: OdoReading? {
    sortedReadings.last
  }

  /// The odometer value a new reading must not fall below: the latest reading,
  /// or the vehicle's starting mileage when there are no readings yet.
  var minimumNextReadingValue: Int {
    Int(latestReading?.value ?? starting)
  }

  var lengthUnitShortForm: String {
    (LengthUnit(rawValue: lengthUnit) ?? .Imperial).shortFor
  }

  /// A human readable lease subtitle like "2024 Oct - 2027 Oct • 36 months".
  var leaseSubtitle: String? {
    guard let start = startDate, lengthOfLease > 0 else { return nil }
    let end = Calendar.current.date(byAdding: .month, value: Int(lengthOfLease), to: start) ?? start
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy MMM"
    let startStr = fmt.string(from: start)
    let endStr = fmt.string(from: end)
    let months = Int(lengthOfLease)
    return "\(startStr) - \(endStr) • \(months) months"
  }
  
  /// Stable identifier shared by the widget configuration, Siri intents, and the
  /// widget deep link.
  var entityIdentifier: String {
    objectID.uriRepresentation().absoluteString
  }

  var lastTeslaSyncKey: String {
    "last_tesla_sync_\(objectID.uriRepresentation().absoluteString)"
  }
  
  var lastTeslaSyncDate: Date? {
    UserDefaults.standard.object(forKey: lastTeslaSyncKey) as? Date
  }
  
  func updateLastTeslaSyncDate() {
    UserDefaults.standard.set(Date(), forKey: lastTeslaSyncKey)
  }

  var pinnedMessageKey: String {
    "pinned_message_\(objectID.uriRepresentation().absoluteString)"
  }

  var pinnedMessageIndex: Int {
    get {
      let stored = UserDefaults.standard.integer(forKey: pinnedMessageKey)
      return max(0, min(2, stored))
    }
    set { UserDefaults.standard.set(newValue, forKey: pinnedMessageKey) }
  }

  var statsOrderKey: String {
    "stats_order_\(objectID.uriRepresentation().absoluteString)"
  }

  var statsOrder: [String] {
    get {
      let stored = UserDefaults.standard.stringArray(forKey: statsOrderKey)
      if let stored = stored, stored.count == 3 {
        return stored
      }
      return ["DAILY AVG", "ODOMETER", "LEASE LEFT"]
    }
    set {
      UserDefaults.standard.set(newValue, forKey: statsOrderKey)
    }
  }
}
