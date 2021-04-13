//
//  Color+Extensions.swift
//  Leastimator
//
//  Created by Hao Liu on 4/11/21.
//

import SwiftUI

extension Color {
  static var mainText: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) :
            UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) })
  }
  
  static var subText: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
            UIColor(red: 104/255, green: 103/255, blue: 111/255, alpha: 1) :
            UIColor(red: 104/255, green: 103/255, blue: 111/255, alpha: 1.0) })
  }
  
  static var mainBg: Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ?
            UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) :
            UIColor(red: 1, green: 1, blue: 1, alpha: 1.0) })
  }
}
