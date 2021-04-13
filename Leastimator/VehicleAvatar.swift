//
//  VehicleAvatar.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct VehicleAvatar: View {
  let data: Data?
  
  var body: some View {
    if let data = data {
      Image(uiImage: UIImage(data: data) ?? UIImage())
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 64, height: 64, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    } else {
      Image(systemName: "car")
        .frame(width: 64, height: 64, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
  }
}

struct VehicleAvatar_Previews: PreviewProvider {
  static var previews: some View {
    Text("")
  }
}
