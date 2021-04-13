//
//  VehicleRow.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

struct VehicleRow: View {
  @ObservedObject var vehicle: Vehicle
  
  var body: some View {
    HStack(spacing: 15) {
      VehicleAvatar(data: vehicle.avatar)
      
      VStack {
        Text(vehicle.name ?? "Unknown vehicle")
          .font(.system(size: 18, weight: .regular))
          .foregroundColor(.mainText)
        // TODO: add current mileage
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
  }
}

struct VehicleRow_Previews: PreviewProvider {
  static var previews: some View {
    Text("test")
  }
}
