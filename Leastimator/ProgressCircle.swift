//
//  ProgressCircle.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct ProgressCircle<Content: View>: View {
  private var progress: Float
  private var colorOverride: Color?
  
  private let strokeWidth: CGFloat = 8.0
  
  @State private var drawingStroke = false
  
  var content: Content
  
  init(progress: Float, colorOverride: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
    self.content = content()
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
      Circle()
        .stroke(lineWidth: strokeWidth)
        .opacity(0.3)
        .foregroundColor(Color.gray)
      
      Circle()
        .trim(from: 0.0, to: drawingStroke ? CGFloat(min(self.progress, 1.0)) : 0.0)
        .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        .foregroundColor(getColor())
        .rotationEffect(Angle(degrees: 270.0))
      
      content
    }
    .animation(animation, value: drawingStroke)
    .onAppear {
      drawingStroke = true
    }
  }
}
