//
//  FontModifiers.swift
//  Leastimator
//
//  Created by Hao Liu on 3/9/23.
//

import SwiftUI

extension Font {
  static func jetBrainsMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom("JetBrainsMono-Regular", size: size).weight(weight)
  }
  
  static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom("Inter", size: size).weight(weight)
  }

  static func roundedFont(_ style: Font.TextStyle) -> Font {
    Font.system(style, design: .rounded)
  }
}
