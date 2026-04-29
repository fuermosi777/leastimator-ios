
import SwiftUI
import Charts

struct HistoryLineChart: View {
    let data: HistoryChartData
    @Binding var selectedDate: Date?
    
    var body: some View {
        Chart {
            // Target Series (Dotted Straight Line)
            ForEach(data.targetPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.statusAmber.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            
            // Actual Series (Line + Area + Markers)
            ForEach(data.actualPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.statusAmber)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.statusAmber)
                .symbolSize(20)
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.statusAmber.opacity(0.25), Color.statusAmber.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // Interaction Rule & Tooltip
            if let selectedDate, let point = findPoint(for: selectedDate) {
                RuleMark(x: .value("Selected", selectedDate))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Color.statusAmber.opacity(0.4))
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.statusAmber)
                .symbolSize(100)
                .annotation(position: .top, spacing: 0) {
                    ChartTooltip(point: point)
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.mainText.opacity(0.05))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val / 1000))k")
                            .font(.jetBrainsMono(9))
                            .foregroundStyle(Color.subText)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.abbreviated))
                            .font(.jetBrainsMono(9))
                            .foregroundStyle(Color.subText)
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot.background(Color.subBg.opacity(0.2).cornerRadius(12))
        }
        .frame(height: 180)
    }
    
    private func findPoint(for date: Date) -> HistoryPoint? {
        data.actualPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
}

struct ChartTooltip: View {
    let point: HistoryPoint
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(point.value))")
                .font(.jetBrainsMono(12, weight: .bold))
                .foregroundColor(.mainText)
            Text(point.date, format: Date.FormatStyle.dateTime.month(.abbreviated).day())
                .font(.inter(9))
                .foregroundColor(.subText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.subBg)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.mainText.opacity(0.1), lineWidth: 1)
        )
        .offset(y: -8)
    }
}
