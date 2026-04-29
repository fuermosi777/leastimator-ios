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
  private let length: Float
  private let lineHeight: CGFloat = 8.0
  
  @State private var drawingStroke = false
  
  init(progress: Float, colorOverride: Color? = nil, length: Float) {
    self.progress = progress
    self.colorOverride = colorOverride
    self.length = length
  }
  
  private var barColor: Color {
    if let colorOverride = colorOverride {
      return colorOverride
    }
    return Color.statusColor(progress: Double(progress))
  }
  
  let animation = Animation
    .easeOut(duration: 0.5)
    .delay(0.2)
  
  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: lineHeight / 2)
        .fill(Color.mainText.opacity(0.05))
        .frame(width: CGFloat(length), height: lineHeight)
      
      RoundedRectangle(cornerRadius: lineHeight / 2)
        .fill(barColor)
        .frame(width: (drawingStroke ? CGFloat(length * min(progress, 1.0)) : 0.0), height: lineHeight)
        .shadow(color: barColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    .animation(animation, value: drawingStroke)
    .onAppear {
      drawingStroke = true
    }
  }
}
