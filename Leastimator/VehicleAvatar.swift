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
  
  init(data: Data?, size: CGFloat = 64.0) {
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
    } else {
      Image(systemName: "car.side")
        .frame(width: size, height: size, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: size / 2, style: .continuous))
    }
  }
}
