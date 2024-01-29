//
//  GraphPoint.swift
//  Leastimator
//
//  Created by Hao Liu on 10/21/23.
//

import Foundation

struct GraphPoint: Hashable, Identifiable {
  var id = UUID()
  
  var value: Double
  var label: String
  
  // Whether the value is marked as significant.
  var significant: Bool
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(String(value) + label)
  }
}

extension Array where Element == GraphPoint {
  func scrollStarter() -> String {
    if self.count > 4 {
      return self[self.count - 5].label
    } else if !self.isEmpty {
      return self.first!.label
    }
    return ""
  }
}
