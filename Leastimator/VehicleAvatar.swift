//
//  VehicleAvatar.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct VehicleAvatar: View {
  let data: Data?
  let size: CGFloat
  
  private let coverRatioToSize = 1.2
  
  init(data: Data?, size: CGFloat) {
    self.data = data
    self.size = size
  }
  
  var body: some View {
    if let data = data {
      Image(uiImage: UIImage(data: data) ?? UIImage())
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: size, height: size, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: size / 2, style: .continuous))
        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
    } else {
      Image("CarCover")
        .resizable()
        .scaledToFit()
        .frame(width: size * coverRatioToSize, alignment: .center)
    }
  }
}
