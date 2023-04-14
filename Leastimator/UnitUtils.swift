//
//  UnitUtils.swift
//  Leastimator
//
//  Created by Hao Liu on 4/11/21.
//

import Foundation
import SwiftUI

enum LengthUnit: Int16, CaseIterable {
  case Imperial = 1,
       Metric = 2
}

extension LengthUnit {
  var shortFor: String {
    switch self {
      case .Imperial: return "mi"
      case .Metric: return "km"
    }
  }
  
  var longName: LocalizedStringKey {
    switch self {
      case .Imperial: return "Mile"
      case .Metric: return "Kilometer"
    }
  }
}

enum Currency: String, CaseIterable {
  case usd = "$",
       cny = "¥",
       eur = "€",
       gbp = "£"
}
