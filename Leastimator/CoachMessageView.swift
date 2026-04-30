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
        .font(.inter(13, weight: .bold))
        .foregroundColor(.subText)
    }
  }
}

struct StatCell: View {
  let label: String
  let value: String
  let unit: String
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .font(.inter(9, weight: .medium))
        .foregroundColor(.subText)
        .tracking(1.0)
      HStack(alignment: .lastTextBaseline, spacing: 2) {
        Text(value)
          .font(.jetBrainsMono(22))
          .fontWeight(.bold)
          .monospacedDigit()
          .foregroundColor(.mainText)
        Text(unit)
          .font(.inter(10, weight: .semibold))
          .foregroundColor(.subText)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, 16)
  }
}
