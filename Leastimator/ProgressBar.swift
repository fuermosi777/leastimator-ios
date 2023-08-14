//
//  ProgressBar.swift
//  Leastimator
//
//  Created by Hao Liu on 8/13/23.
//

import SwiftUI

struct ProgressBar: View {
  private var progress: Float
  private var colorOverride: Color?
  
  private let strokeWidth: CGFloat = 8.0
  private let lineWidth: Float = 200.0
  private let lineHeight: CGFloat = 8.0
  
  @State private var drawingStroke = false
  
  init(progress: Float, colorOverride: Color? = nil) {
    self.progress = progress
    self.colorOverride = colorOverride
  }
  
  private func getColor() -> Color {
    if let colorOverride = colorOverride {
      return colorOverride
    }
    if progress >= 1.0 {
      return Color.red
    } else if progress >= 0.9 {
      return Color.orange
    } else {
      return Color.accentColor
    }
  }
  
  let animation = Animation
    .easeOut(duration: 0.5)
    .delay(0.2)
  
  var body: some View {
    ZStack {
      HStack {
        RoundedRectangle(cornerRadius: lineHeight / 2)
          .fill(Color.gray)
          .frame(width: CGFloat(lineWidth), height: lineHeight)
          .opacity(0.3)
        Spacer()
      }
      
      HStack {
        RoundedRectangle(cornerRadius: lineHeight / 2)
          .fill(getColor())
          .frame(width: (drawingStroke ? CGFloat(lineWidth * progress) : 0.0), height: lineHeight)
        Spacer()
      }
    }
    .animation(animation, value: drawingStroke)
    .onAppear {
      drawingStroke = true
    }
  }
}
