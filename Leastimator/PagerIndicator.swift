//
//  PagerIndicator.swift
//  Leastimator
//
//  Created by Hao Liu on 4/24/21.
//

import SwiftUI

struct PagerIndicator: View {
  var size: Int
  @Binding var focusIndex: Int
  
  var body: some View {
    HStack {
      ForEach(0..<size, id: \.self) { index in
        if focusIndex == index {
          Circle()
            .fill(Color.focusedIndicator)
            .frame(width: 5, height: 5)
        } else {
          Circle()
            .fill(Color.dismissedIndicator)
            .frame(width: 5, height: 5)
        }
      }
    }
  }
}
