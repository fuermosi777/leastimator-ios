//
//  Int+Extensions.swift
//  Leastimator
//
//  Created by Hao Liu on 4/24/21.
//

import Foundation

extension Int {
  func toOdometerReading(_ maxDigit: Int = 6) -> String {
    let intStr = String(self)
    var needZeroCount = maxDigit - intStr.count
    if needZeroCount < 0 {
      needZeroCount = 0
    }
    var finalStr = ""
    for _ in 0..<needZeroCount {
      finalStr += "0"
    }
    finalStr += intStr
    return finalStr
  }
}
