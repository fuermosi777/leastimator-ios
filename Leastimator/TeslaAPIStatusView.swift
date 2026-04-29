//
//  TeslaAPIStatusView.swift
//  Leastimator
//
//  Created by Antigravity on 4/28/26.
//

import SwiftUI

struct TeslaAPIStatusView: View {
  let state: String?
  
  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: state?.lowercased() == "online" ? "bolt.car.fill" : "moon.zzz.fill")
      Text("API: \(state?.capitalized ?? "Checking...")")
    }
    .font(.inter(11, weight: .bold))
    .foregroundColor(state?.lowercased() == "online" ? .green : .subText)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.subBg.opacity(0.3))
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
    )
    .cornerRadius(12)
  }
}
