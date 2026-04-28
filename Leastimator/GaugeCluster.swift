import SwiftUI

struct GaugeCluster: View {
    var progress: Float
    var projected: Int
    var variance: Int
    var unit: String
    
    private let size: CGFloat = 280
    private let stroke: CGFloat = 12
    private let arc: Double = 0.75 // sweep angle (270 degrees)
    private let startAngle: Double = 135 // starting from bottom left
    
    private var color: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.9 {
            return .orange
        } else {
            return .accentColor
        }
    }
    
    var body: some View {
        ZStack {
            // Background ticks
            Ticks(count: 40, progress: progress, color: color)
                .frame(width: size, height: size)
            
            // Progress Arc
            Circle()
                .trim(from: 0, to: CGFloat(arc))
                .stroke(Color.subBg, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .frame(width: size - 40, height: size - 40)
                .rotationEffect(.degrees(startAngle))
            
            Circle()
                .trim(from: 0, to: CGFloat(arc * Double(min(progress, 1.0))))
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .frame(width: size - 40, height: size - 40)
                .rotationEffect(.degrees(startAngle))
                .shadow(color: color.opacity(0.3), radius: 5)
            
            // Center Readout
            VStack(spacing: 4) {
                Text("PROJECTED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.subText)
                    .tracking(2)
                
                Text("\(projected)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.mainText)
                
                Text("\(unit.uppercased()) · BY LEASE END")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.subText)
                    .tracking(1)
                
                HStack(spacing: 4) {
                    Text(variance < 0 ? "-" : "+")
                    Text("\(abs(variance))")
                    Text(unit)
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(variance <= 0 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .foregroundColor(variance <= 0 ? .green : .red)
                .cornerRadius(20)
                .padding(.top, 10)
            }
        }
        .frame(width: size, height: size)
    }
}

struct Ticks: View {
    let count: Int
    let progress: Float
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let r = w / 2
            let arc: Double = 0.75
            let startAngle: Double = 135
            
            ForEach(0...count, id: \.self) { i in
                let t = Double(i) / Double(count)
                let angle = startAngle + t * arc * 360
                let rad = angle * .pi / 180
                
                let isMajor = i % 5 == 0
                let length: CGFloat = isMajor ? 12 : 6
                let x1 = r + cos(rad) * (r - 5)
                let y1 = r + sin(rad) * (r - 5)
                let x2 = r + cos(rad) * (r - 5 - length)
                let y2 = r + sin(rad) * (r - 5 - length)
                
                Path { path in
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))
                }
                .stroke(Double(progress) >= t ? color : Color.subText.opacity(0.3),
                        lineWidth: isMajor ? 2 : 1)
            }
        }
    }
}
