//
//  DashboardGauge.swift
//  Leastimator
//
//  Created by Antigravity on 4/28/26.
//

import SwiftUI

struct DashboardGauge: View {
    let progress: Double // 0.0 to 1.15 (scaled for the gauge arc)
    let projected: Int
    let variance: Int
    let unit: String
    let statusColor: Color
    var showVariance: Bool = true
    
    private let stroke: CGFloat = 14
    private let arc: Double = 0.75 // Use 3/4 of the circle
    private let startAngle: Double = 135 // Starting from bottom-left
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                let size = geo.size.width
                
                ZStack {
                    // Tick marks on the outer rim
                    GaugeTicks(progress: progress, arc: arc, startAngle: startAngle, color: statusColor)
                        .frame(width: size, height: size)
                    
                    // Background arc (the "track")
                    Circle()
                        .trim(from: 0, to: CGFloat(arc))
                        .stroke(Color.mainText.opacity(0.05), style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                        .rotationEffect(.degrees(startAngle))
                        .frame(width: size - 60, height: size - 60)
                    
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: CGFloat(min(progress, 1.0) * arc))
                        .stroke(statusColor, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                        .rotationEffect(.degrees(startAngle))
                        .frame(width: size - 60, height: size - 60)
                        .shadow(color: statusColor.opacity(0.3), radius: 8)
                    
                    // Center readout
                    VStack(spacing: 2) {
                        Text("PROJECTED")
                            .font(.rounded(10, weight: .bold))
                            .foregroundColor(.subText)
                            .tracking(2)
                        
                        Text("\(projected)")
                            .font(.rounded(50))
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundColor(.mainText)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .tracking(-2)
                        
                        Text("\(unit.uppercased()) · BY LEASE END")
                            .font(.rounded(11, weight: .semibold))
                            .foregroundColor(.subText)
                            .tracking(1)
                        
                        if showVariance {
                            Text("\(variance > 0 ? "+" : "")\(variance) \(unit) vs limit")
                                .font(.rounded(12))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(statusColor.opacity(0.10))
                                .foregroundColor(statusColor)
                                .cornerRadius(20)
                                .padding(.top, 10)
                        }
                    }
                    .frame(width: size - 80)
                }
                .frame(width: size, height: size)
                .offset(y: size * 0.06) // Shift down to align the top of the gauge with the frame top
            }
            .aspectRatio(1.15, contentMode: .fit)
        }
        .frame(maxWidth: 300)
    }
}

struct GaugeTicks: View {
    let progress: Double
    let arc: Double
    let startAngle: Double
    let color: Color
    
    let tickCount = 40
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = geo.size.width / 2 - 5
            
            ForEach(0...tickCount, id: \.self) { i in
                let t = Double(i) / Double(tickCount)
                // In SwiftUI rotation, 0 is at 3 o'clock. 
                // We want to start at startAngle.
                let angle = startAngle + t * arc * 360
                let isMajor = i % 5 == 0
                let tickLength: CGFloat = isMajor ? 12 : 6
                
                let start = pointOnCircle(center: center, radius: radius, angle: angle)
                let end = pointOnCircle(center: center, radius: radius - tickLength, angle: angle)
                
                let filled = t <= min(progress, 1.0)
                
                Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                .stroke(filled ? color : Color.mainText.opacity(0.2), lineWidth: isMajor ? 2 : 1)
            }
        }
    }
    
    func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(CGFloat(radians)),
            y: center.y + radius * sin(CGFloat(radians))
        )
    }
}

struct DashboardGauge_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            DashboardGauge(progress: 0.65, projected: 12450, variance: -450, unit: "mi", statusColor: .statusLime)
        }
    }
}
