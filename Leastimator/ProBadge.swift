//
//  ProBadge.swift
//  Leastimator
//
//  Created by Hao Liu on 3/18/23.
//

import SwiftUI

struct ProBadge: View {
  var body: some View {
    Text("pro")
      .font(.system(size: 12, weight: .bold, design: .rounded))
      .foregroundColor(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color.accentColor)
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}
