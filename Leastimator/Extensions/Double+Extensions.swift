//
//  Double+Extensions.swift
//  Leastimator
//
//  Created by Hao Liu on 10/21/23.
//

import Foundation

extension Double {
  func decimalString() -> String {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    return numberFormatter.string(from: NSNumber(value: self)) ?? "0"
  }
}
