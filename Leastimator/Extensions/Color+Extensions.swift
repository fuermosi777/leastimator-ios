//
//  Color+Extensions.swift
//  Leastimator
//
//  Created by Hao Liu on 4/11/21.
//

import SwiftUI

extension UIColor {
  static var title: UIColor {
    UIColor { $0.userInterfaceStyle == .dark ?
      UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1) :
      UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1) }
  }
}

extension Color {
  static var mainText: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
      UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1) :
      UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) })
  }
  
  static var subText: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
      UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1) :
      UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1.0) })
  }
  
  static var mainBg: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
      UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) :
      UIColor(red: 1, green: 1, blue: 1, alpha: 1.0) })
  }
  
  static var bgGradientStart: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
      UIColor(red: 25/255, green: 25/255, blue: 27/255, alpha: 1.0) :
      UIColor(red: 245/255, green: 247/255, blue: 250/255, alpha: 1.0) })
  }
  
  static var bgGradientEnd: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
      UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) :
      UIColor(red: 228/255, green: 232/255, blue: 240/255, alpha: 1.0) })
  }
  
  static var subBg: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
      UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0) :
      UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0) })
  }
  
  static var focusedIndicator: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
      UIColor.lightGray : UIColor.gray})
  }
  
  static var dismissedIndicator: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
      UIColor.gray : UIColor.lightGray })
  }

  static var statusRed: Color { Color(red: 255/255, green: 59/255, blue: 48/255) } // Rose Red
  static var statusAmber: Color { Color(red: 255/255, green: 159/255, blue: 10/255) } // Amber Orange
  static var statusLime: Color { Color(red: 50/255, green: 215/255, blue: 75/255) } // Lime Green

  /// Red at/over 100% of the allowance (fixed); amber from the user-configurable
  /// warning start; lime below that.
  static func statusColor(progress: Double, warningStart: Double = StatusThreshold.warningStart) -> Color {
      if progress >= 1.0 { return .statusRed }
      if progress >= warningStart { return .statusAmber }
      return .statusLime
  }
}

/// User-configurable point (percent of allowance) where the status color turns amber.
/// Stored in the App Group so the widget extension sees the same value.
enum StatusThreshold {
  static let warningStartKey = "statusWarningStartPercent"
  static let defaultWarningStartPercent = 90
  static let warningStartRange = 75...99
  static let store = UserDefaults(suiteName: "group.im.liuhao.leastimator") ?? .standard

  static func fraction(fromPercent percent: Int) -> Double {
    let clamped = min(max(percent, warningStartRange.lowerBound), warningStartRange.upperBound)
    return Double(clamped) / 100
  }

  static var warningStart: Double {
    let stored = store.object(forKey: warningStartKey) as? Int ?? defaultWarningStartPercent
    return fraction(fromPercent: stored)
  }
}
