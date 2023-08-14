//
//  StoreKit+Extensions.swift
//
//  Created by Hao Liu on 8/12/23.
//

import Foundation
import StoreKit

extension Product {
  var displayPriceWithPeriod: String {
    var period: String = ""
    if let subscription = self.subscription {
      if subscription.subscriptionPeriod.unit == .month {
        period = "month"
      } else if subscription.subscriptionPeriod.unit == .year {
        period = "year"
      }
    }
    
    if period.isEmpty {
      return self.displayPrice
    } else {
      return "\(self.displayPrice) per \(period)"
    }
  }
}
