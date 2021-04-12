//
//  UnitUtils.swift
//  Leastimator
//
//  Created by Hao Liu on 4/11/21.
//

import Foundation

enum LengthUnit: Int16, CaseIterable {
  case mi = 1,
       km = 2
}

extension LengthUnit {
  var shortFor: String {
    switch self {
    case .mi: return "mi"
    case .km: return "km"
    }
  }
  
  var longName: String {
    switch self {
    case .mi: return "mile"
    case .km: return "kilometer"
    }
  }
  
  var longNames: String {
    return self.longName + "s"
  }
}

enum Currency: String, CaseIterable {
  case usd = "$",
       cny = "¥",
       eur = "€",
       gbp = "£"
}
