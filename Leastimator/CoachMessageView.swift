//
//  CoachMessageView.swift
//  Leastimator
//
//  Created by Antigravity on 4/28/26.
//

import SwiftUI

struct CoachMessage: View {
  let isOverPace: Bool
  var activeAlert: ActiveVehicleAlert? = nil

  private var dotColor: Color {
    if let activeAlert {
      return activeAlert.isGoodNews ? .accentColor : .red
    }
    return isOverPace ? .red : .accentColor
  }

  private var message: String {
    if let activeAlert {
      return activeAlert.message
    }
    return isOverPace ? "Heads up — you're over pace" : "Nice pace. You're on track."
  }

  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(dotColor)
        .frame(width: 8, height: 8)
        .shadow(color: dotColor, radius: 4)
      Text(LocalizedStringKey(message))
        .font(.rounded(13, weight: .bold))
        .foregroundColor(.subText)
        .lineLimit(2)
    }
  }
}

struct StatCell: View {
  let label: String
  let value: String
  let unit: String
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(LocalizedStringKey(label))
        .font(.rounded(9, weight: .medium))
        .foregroundColor(.subText)
        .tracking(1.0)
      HStack(alignment: .lastTextBaseline, spacing: 2) {
        Text(value)
          .font(.rounded(22))
          .fontWeight(.bold)
          .monospacedDigit()
          .foregroundColor(.mainText)
        Text(unit)
          .font(.rounded(10, weight: .semibold))
          .foregroundColor(.subText)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, 16)
  }
}
