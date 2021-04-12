//
//  ProgressCircle.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct ProgressCircle<Content: View>: View {
  private var progress: Float
  
  private let strokeWidth: CGFloat = 7.0
  
  var content: Content
  
  init(progress: Float, @ViewBuilder content: @escaping () -> Content) {
    self.content = content()
    self.progress = progress
  }
  
  private func getColor() -> Color {
    if progress >= 1.0 {
      return Color.red
    } else if progress >= 0.9 {
      return Color.orange
    } else {
      return Color.accentColor
    }
  }
  
  var body: some View {
    ZStack {
      Circle()
        .stroke(lineWidth: strokeWidth)
        .opacity(0.3)
        .foregroundColor(Color.gray)
      
      Circle()
        .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
        .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        .foregroundColor(getColor())
        .rotationEffect(Angle(degrees: 270.0))
        .animation(.linear)
      
      content
    }
  }
}
