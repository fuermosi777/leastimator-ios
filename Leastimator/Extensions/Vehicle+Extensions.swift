//
//  Vehicle+Extensions.swift
//  Leastimator
//
//  Created by Hao on 1/1/26.
//

import Foundation

extension Vehicle {
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
}
