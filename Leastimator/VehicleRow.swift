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
    HStack {
      VehicleAvatar(data: vehicle.avatar)
      
      VStack {
        Text(vehicle.name ?? "Unknown vehicle")
          .font(.system(size: 18, weight: .regular))
          .foregroundColor(.mainText)
        // TODO: add current mileage
      }
      
      Spacer()
    }
  }
}
