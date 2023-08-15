//
//  VehicleAvatar.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct VehicleAvatar: View {
  let data: Data?
  
  init(data: Data?) {
    self.data = data
  }
  
  var body: some View {
    if let data = data {
      Image(uiImage: UIImage(data: data) ?? UIImage())
        .resizable()
        .scaledToFit()
        .frame(width: 180.0, alignment: .center)
        .clipShape(Circle())
    } else {
      Image("CarCover")
        .resizable()
        .scaledToFit()
        .frame(width: 260.0, alignment: .center)
    }
  }
}
