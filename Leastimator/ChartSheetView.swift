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

  @State private var selectedLabel: String? = nil

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

  var yMin: Double {
    max(0.0, Double(vehicle.starting) - 500.0)
  }

  var yMax: Double {
    Double(max(extendedInfo.currentMileage, extendedInfo.mileageShouldLessThan)) + 2000.0
  }

  var currentMonthLabel: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM yyyy"
    return formatter.string(from: Date())
  }

  var selectedPoint: GraphPoint? {
    guard let label = selectedLabel else { return nil }
    return extendedInfo.monthlyMileageDataForLineChart.first { $0.label == label }
  }

  let linearGradient = LinearGradient(
    gradient: Gradient(
      colors: [
        .accentColor.opacity(0.5),
        .accentColor.opacity(0.2),
        .accentColor.opacity(0.0),
      ]
    ),
    startPoint: .top, endPoint: .bottom)

  var body: some View {
    VStack(spacing: 0) {
      // Header
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
      .padding(.bottom, 12)

      // Stat strip
      HStack(spacing: 0) {
        statCell(label: "Current", value: Double(extendedInfo.currentMileage).decimalString(), color: .mainText)
        Divider().frame(height: 32)
        statCell(label: "Allowed", value: Double(extendedInfo.mileageShouldLessThan).decimalString(), color: .mainText)
        Divider().frame(height: 32)
        statCell(label: "Remaining", value: Double(extendedInfo.leftMileage).decimalString(), color: allowanceColor)
      }
      .padding(.horizontal)
      .padding(.bottom, 16)

      // Chart
      Chart {
        ForEach(extendedInfo.monthlyMileageDataForLineChart) { point in
          LineMark(x: .value("Month", point.label), y: .value("Value", point.value))
            .interpolationMethod(.monotone)

          AreaMark(x: .value("Month", point.label), y: .value("Value", point.value))
            .foregroundStyle(linearGradient)
            .interpolationMethod(.monotone)

          if point.significant {
            PointMark(x: .value("Month", point.label), y: .value("Value", point.value))
              .symbolSize(40)
          }
        }

        // Today marker
        if extendedInfo.monthlyMileageDataForLineChart.contains(where: { $0.label == currentMonthLabel }) {
          RuleMark(x: .value("Today", currentMonthLabel))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .foregroundStyle(Color.subText.opacity(0.5))
        }

        // Allowance line
        RuleMark(y: .value("Max Allowance", extendedInfo.mileageShouldLessThan))
          .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
          .foregroundStyle(allowanceColor.opacity(0.8))
          .annotation(position: .top, alignment: .trailing) {
            Text(Double(extendedInfo.mileageShouldLessThan).decimalString())
              .font(.caption2)
              .foregroundStyle(allowanceColor.opacity(0.8))
          }

        // Selection indicator
        if let point = selectedPoint {
          RuleMark(x: .value("Selected", point.label))
            .lineStyle(StrokeStyle(lineWidth: 1))
            .foregroundStyle(Color.accentColor.opacity(0.4))
          PointMark(x: .value("Month", point.label), y: .value("Value", point.value))
            .symbolSize(80)
            .annotation(position: .top) {
              Text(point.value.decimalString())
                .font(.caption2.bold())
                .foregroundStyle(Color.mainText)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.subBg.cornerRadius(6))
            }
        }
      }
      .chartYAxis {
        AxisMarks(values: .automatic(desiredCount: 4)) {
          AxisGridLine()
          AxisTick()
          AxisValueLabel()
        }
      }
      .chartYScale(domain: yMin...yMax)
      .chartScrollableAxes(.horizontal)
      .chartScrollPosition(initialX: extendedInfo.monthlyMileageDataForLineChart.scrollStarter())
      .chartXVisibleDomain(length: 5)
      .chartXSelection(value: $selectedLabel)
      .chartPlotStyle { plot in
        plot.background(Color.subBg.opacity(0.4).cornerRadius(12))
      }
      .frame(height: 280)
      .padding(.horizontal)
      .padding(.bottom, 20)
    }
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }

  @ViewBuilder
  private func statCell(label: String, value: String, color: Color) -> some View {
    VStack(spacing: 4) {
      Text(label)
        .font(.caption)
        .foregroundColor(.subText)
      Text(value)
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .foregroundColor(color)
    }
    .frame(maxWidth: .infinity)
  }
}
