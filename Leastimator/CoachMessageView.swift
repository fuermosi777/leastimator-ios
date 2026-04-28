//
//  CoachMessageView.swift
//  Leastimator
//
//  Created by Antigravity on 4/28/26.
//

import SwiftUI

struct CoachMessage: View {
  let isOverPace: Bool
  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(isOverPace ? Color.red : Color.accentColor)
        .frame(width: 8, height: 8)
        .shadow(color: isOverPace ? Color.red : Color.accentColor, radius: 4)
      Text(isOverPace ? "Heads up — you're over pace" : "Nice pace. You're on track.")
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .foregroundColor(.subText)
    }
    .padding(.top, 8)
  }
}

struct StatCell: View {
  let label: String
  let value: String
  let unit: String
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .font(.system(size: 9, weight: .medium, design: .rounded))
        .foregroundColor(.subText)
        .tracking(1.0)
      HStack(alignment: .lastTextBaseline, spacing: 2) {
        Text(value)
          .font(.system(size: 22, weight: .bold, design: .monospaced))
          .monospacedDigit()
          .foregroundColor(.mainText)
        Text(unit)
          .font(.system(size: 10, weight: .semibold, design: .rounded))
          .foregroundColor(.subText)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, 16)
  }
}
