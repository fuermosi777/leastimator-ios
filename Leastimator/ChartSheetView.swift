//
//  ChartSheetView.swift
//  Leastimator
//
//  Created by Hao on 1/1/26.
//

import SwiftUI
import Charts

struct ChartSheetView: View {
  var extendedInfo: ExtendedVehicleInfo
  var vehicle: Vehicle
  @Environment(\.dismiss) var dismiss

  var allowanceColor: Color {
    let current = extendedInfo.currentMileage
    let max = extendedInfo.mileageShouldLessThan
    if current > max {
      return .red
    } else if Double(current) >= Double(max) * 0.9 {
      return .orange
    } else {
      return .green
    }
  }

  let linearGradient = LinearGradient(
    gradient: Gradient (
      colors: [
        .accentColor.opacity(0.6),
        .accentColor.opacity(0.4),
        .accentColor.opacity(0.0),
      ]
    ),
    startPoint: .top, endPoint: .bottom)

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Text("Mileage Chart")
          .font(.headline)
        Spacer()
        Button(action: { dismiss() }) {
          Image(systemName: "xmark.circle.fill")
            .font(.title2)
            .foregroundColor(.subText)
        }
        .buttonStyle(.borderless)
      }
      .padding([.top, .horizontal])

      Chart {
        ForEach(extendedInfo.monthlyMileageDataForLineChart) { point in
          LineMark(x: .value("Month", point.label), y: .value("Value", point.value))

          if point.label == extendedInfo.monthlyMileageDataForLineChart.last?.label {
            PointMark(x: .value("Month", point.label), y: .value("Value", point.value))
              .annotation {
                Text(point.value.decimalString())
                  .font(.caption)
                  .foregroundStyle(Color.mainText)
              }
          } else if point.value > 0 {
            PointMark(x: .value("Month", point.label), y: .value("Value", point.value))
          }

          AreaMark(x: .value("Date", point.label), y: .value("Value", point.value))
            .foregroundStyle(linearGradient)
        }

        RuleMark(y: .value("Max Allowance", extendedInfo.mileageShouldLessThan))
          .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
          .foregroundStyle(allowanceColor.opacity(0.8))
          .annotation(position: .top, alignment: .trailing) {
            Text(Double(extendedInfo.mileageShouldLessThan).decimalString())
              .font(.caption2)
              .foregroundStyle(allowanceColor.opacity(0.8))
          }
      }
      .chartYAxis { AxisMarks { _ in AxisGridLine(); AxisTick(); AxisValueLabel() } }
      .chartYScale(domain: 0...max(extendedInfo.currentMileage, extendedInfo.mileageShouldLessThan) + 2000)
      .chartScrollableAxes(.horizontal)
      .chartScrollPosition(initialX: extendedInfo.monthlyMileageDataForLineChart.scrollStarter())
      .chartXVisibleDomain(length: 5)
      .frame(height: 320)
      .padding(.horizontal)

      Spacer()
    }
    .presentationDetents([.medium, .large])
  }
}

