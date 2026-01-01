//
//  Views+Extensions.swift
//  Leastimator
//
//  Created by Hao on 1/1/26.
//

import SwiftUI

extension View {
  func widgetBackground(_ backgroundView: some View) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      return containerBackground(for: .widget) {
        backgroundView
      }
    } else {
      return background(backgroundView)
    }
  }
}

// Helper to conditionally apply navigationSubtitle when available
extension View {
  @ViewBuilder func applyNavigationSubtitle(_ subtitle: String?) -> some View {
    if #available(iOS 26.0, *) {
      if let s = subtitle {
        self.navigationSubtitle(s)
      } else {
        self
      }
    } else {
      self
    }
  }
}
