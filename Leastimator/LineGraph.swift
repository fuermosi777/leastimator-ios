//
//  LineGraph.swift
//  Leastimator
//
//  Created by Hao Liu on 3/7/23.
//

import SwiftUI

extension CGPoint : Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
  }
}

struct GraphPoint: Hashable, Identifiable {
  var id = UUID()
  
  var value: Double
  var label: String
  
  // Whether the value is marked as significant.
  var significant: Bool
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(String(value) + label)
  }
}

struct LineGraph: View {
  var data: [GraphPoint]
  
  private var yLimit: Double
  private var chartHeight: CGFloat = 180.0
  // Distance between each label on x-axis.
  private var xLabelGap: CGFloat
  private var xLabelSize: CGFloat = 12.0
  private var xOffset: CGFloat = 48.0
  
  private var points = [CGPoint]()
  private var limitPoint = CGPoint()
  
  @Namespace var currentPointID
  
  init(data: [GraphPoint], xLabelGap: CGFloat = 40.0, yLimit: Double = 0.0) {
    self.data = data
    self.xLabelGap = xLabelGap
    self.yLimit = yLimit
    
    // Generate points.
    var maxValue = data.max { $0.value < $1.value }?.value ?? -1
    maxValue = max(maxValue, yLimit)
    for i in 0..<data.count {
      if data[i].value == -1.0 {
        continue
      }
      points.append(computePoint(index: i, value: data[i].value,
                                 maxValue: maxValue, height: chartHeight))
    }
    
    limitPoint = computePoint(index: 0, value: yLimit, maxValue: maxValue, height: chartHeight)
  }
  
  private func computePoint(index: Int, value: Double, maxValue: Double, height: CGFloat) -> CGPoint {
    let x = CGFloat(index) * xLabelGap + xOffset
    // How much area the line chart should occupy in the chart.
    // We don't want to stick the max value to the top.
    let totalLineRatio = 0.75
    let ratio: Double = value / maxValue * totalLineRatio
    let y = height * (1 - ratio) - (xLabelSize * 2) // Offset for labels
    return CGPoint(x: x, y: y)
  }
  
  var body: some View {
    ScrollViewReader { reader in
      ZStack {
        // Draw y limit line.
        if yLimit > 0 {
          Path { path in
            path.move(to: CGPoint(x: xOffset, y: limitPoint.y))
            path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: limitPoint.y))
          }.stroke(Color.red.opacity(0.38), style: StrokeStyle(lineWidth: 1.0, dash: [3]))
          
          Text(String(Int(yLimit)))
            .position(x: UIScreen.main.bounds.width, y: limitPoint.y - 10.0)
            .font(.system(size: 13, design: .rounded))
            .foregroundColor(Color.red.opacity(0.38))
        }
        
        ScrollView(.horizontal, showsIndicators: false) {
          VStack {
            ZStack {
              // Draw history line.
              Path { path in
                for i in 0..<points.count {
                  let point = points[i]
                  if i == 0 {
                    path.move(
                      to: point
                    )
                  } else {
                    path.addLine(to: point)
                  }
                }
              }
              .stroke(Color.accentColor, lineWidth: 3.0)
              
              // Gradient Background
              Path { path in
                for i in 0..<points.count {
                  let point = points[i]
                  if i == 0 {
                    path.move(
                      to: point
                    )
                  } else {
                    path.addLine(to: point)
                  }
                }
                // Connect to the bottom.
                path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: chartHeight))
                path.addLine(to: CGPoint(x: xOffset, y: chartHeight))
              }
              .fill(LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.38),
                                                               Color.accentColor.opacity(0)]), startPoint: .top, endPoint: .bottom))
              
              // Past points background.
              ForEach(points, id:\.self) { point in
                Circle()
                  .strokeBorder(Color.accentColor, lineWidth: 3)
                  .background(Circle().foregroundColor(Color.mainBg))
                  .frame(width: 10, height: 10)
                  .position(x: point.x, y: point.y)
              }
              
              // The latest point
              Circle()
                .strokeBorder(Color.accentColor, lineWidth: 3)
                .background(Circle().foregroundColor(Color.mainBg))
                .frame(width: 13, height: 13)
                .position(x: points.last?.x ?? xOffset, y: points.last?.y ?? chartHeight)
                .id(currentPointID)
              
              // Current label.
              if let lastData = data.last {
                Text(String(Int(lastData.value)))
                  .position(x: points.last?.x ?? xOffset, y: (points.last?.y ?? chartHeight) - 15.0)
                  .font(.system(size: 13, weight: .bold, design: .rounded))
                  .foregroundColor(.mainText)
              }
              
              // Labels
              ForEach(0..<data.count, id: \.self) { i in
                Text(data[i].label.uppercased())
                  .position(x: CGFloat(i) * xLabelGap + xOffset, y: chartHeight - xLabelSize / 2)
                  .font(.system(size: xLabelSize))
                  .foregroundColor(Color.subText)
              }
            }
            
          } // VStack
          .frame(width: xLabelGap * CGFloat(data.count) + xOffset * 2,
                 height: chartHeight)
        }
        .onAppear { reader.scrollTo(currentPointID) }
      }
    }
  }
  
}
