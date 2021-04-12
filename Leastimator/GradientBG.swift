//
//  GradientBG.swift
//  Leastimator
//
//  Created by Hao Liu on 4/6/21.
//

import SwiftUI

struct GradientBG: View {
  var body: some View {
    LinearGradient(gradient: Gradient(colors: [Color("LessBlack"), .black]), startPoint: .top, endPoint: .bottom)
      .edgesIgnoringSafeArea(.all)
  }
}

struct GradientBG_Previews: PreviewProvider {
  static var previews: some View {
    GradientBG()
  }
}
