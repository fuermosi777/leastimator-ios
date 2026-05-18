//
//  FontModifiers.swift
//  Leastimator
//
//  Created by Hao Liu on 3/9/23.
//

import SwiftUI

extension Font {

  static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .rounded)
  }

  static func roundedFont(_ style: Font.TextStyle) -> Font {
    Font.system(style, design: .rounded)
  }
}
