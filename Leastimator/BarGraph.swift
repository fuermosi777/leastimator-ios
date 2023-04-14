//
//  BarGraph.swift
//  Leastimator
//
//  Created by Hao Liu on 4/13/23.
//

import SwiftUI

struct BarGraph: View {
  var data: [GraphPoint]
  
  private var chartHeight: CGFloat = 150.0
  
  private var maxValue: Double {
    return data.max { $0.value < $1.value }?.value ?? -1
  }
  
  @Namespace var currentPointID
  
  var heights = [CGFloat]()
  
  init(data: [GraphPoint]) {
    self.data = data
  }
  
  var body: some View {
    ScrollViewReader { reader in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10.0) {
          ForEach(0..<data.count) { i in
            ZStack {
              VStack {
                if i == data.count - 1 {
                  Text(String(Int(data[i].value)))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.mainText)
                }
                Spacer()
              }
              VStack {
                Spacer()
                if data[i].significant {
                  Capsule().frame(width: 4.0, height: data[i].value / maxValue * chartHeight )
                    .foregroundColor(.accentColor)
                } else {
                  Capsule().frame(width: 4.0, height: data[i].value / maxValue * chartHeight )
                    .foregroundColor(.subBg)
                }
                Text(data[i].label)
                  .foregroundColor(.subText)
                  .font(.system(size: 11.0))
              }.frame(width: 16.0)
            }
          }
          
          VStack {}.id(currentPointID)
        }.onAppear { reader.scrollTo(currentPointID) }
      }
    }
  }
}

