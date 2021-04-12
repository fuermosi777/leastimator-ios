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
}
