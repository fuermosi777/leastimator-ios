//
//  Modifiers.swift
//
//  Created by Hao Liu on 3/25/23.
//

import SwiftUI

struct Card: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding()
      .background(Color.subBg)
      .cornerRadius(20.0)
  }
}

extension View {
  func cardLike() -> some View {
    modifier(Card())
  }
}
