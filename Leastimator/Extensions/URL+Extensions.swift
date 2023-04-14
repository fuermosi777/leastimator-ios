//
//  URL+Extensions.swift
//  Leastimator
//
//  Created by Hao Liu on 5/14/21.
//

import Foundation

enum DeepLinkIdentifier: Hashable {
  case addReading
}

extension URL {
  var isDeepLink: Bool {
    return scheme == "leastimator"
  }
  
  var deepLinkIdentifier: DeepLinkIdentifier? {
    guard isDeepLink else { return nil }
    switch host {
      case "add-reading":
        return .addReading
      default: return nil
    }
  }
}
