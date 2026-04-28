//
//  FontModifiers.swift
//  Leastimator
//
//  Created by Hao Liu on 3/9/23.
//

import SwiftUI

extension Font {
  static func jetBrainsMono(_ size: CGFloat) -> Font {
    .custom("JetBrainsMono-Regular", size: size)
  }
  
  static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    // Inter is often registered as "Inter" or "Inter-Regular"
    .custom("Inter-Regular", size: size)
  }

  static func roundedFont(_ style: Font.TextStyle) -> Font {
    Font.system(style, design: .rounded)
  }
}
