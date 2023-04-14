//
//  Date+Extensions.swift
//  Leastimator
//
//  Created by Hao Liu on 4/11/21.
//

import Foundation

extension Date {
  func format() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, y"
    return formatter.string(from: self)
  }
  
  // Return the first date of the current month.
  func startOfMonth() -> Date {
    return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
  }
  
  func endOfMonth() -> Date {
    return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth())!
  }
}
