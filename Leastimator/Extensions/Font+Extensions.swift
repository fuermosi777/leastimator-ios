//
//  FontModifiers.swift
//  Leastimator
//
//  Created by Hao Liu on 3/9/23.
//

import SwiftUI

extension Font {
  static func roundedFont(_ style: Font.TextStyle) -> Font {
    Font.system(style, design: .rounded)
  }
}
