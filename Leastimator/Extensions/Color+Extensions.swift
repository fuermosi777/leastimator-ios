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
}
