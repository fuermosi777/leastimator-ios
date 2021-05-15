//
//  SettingsView.swift
//  Leastimator
//
//  Created by Hao Liu on 4/11/21.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
  @Environment(\.managedObjectContext) private var viewContext
  
  var vehicles: FetchedResults<Vehicle>
  var onDismiss: () -> Void
  
  @State private var selectedVehicleIndex: Int
  @State private var showVehiclePicker = false
  
  @AppStorage("lineChartShowOriginalData") private var lineChartShowOriginalData = false
  
  init(vehicles: FetchedResults<Vehicle>, onDismiss: @escaping () -> Void) {
    self.vehicles = vehicles
    self.onDismiss = onDismiss
    
    var initialVehicleIndex = -1
    if vehicles.count > 0 {
      initialVehicleIndex = 0
    }
    for (index, vehicle) in vehicles.enumerated() {
      if vehicle.showOnWidget {
        initialVehicleIndex = index
      }
    }

    _selectedVehicleIndex = State(initialValue: initialVehicleIndex)
  }
  
  var body: some View {
    NavigationView {
      VStack(alignment: .leading, spacing: 10.0) {
        if vehicles.count > 0 {
          Button(action: { showVehiclePicker.toggle() }) {
            HStack {
              Text("Vehicle on widget").foregroundColor(.mainText)
              Spacer()
              Text(String(self.vehicles[selectedVehicleIndex].name ?? "--"))
            }
          }
          
          if showVehiclePicker {
            Picker("", selection: $selectedVehicleIndex) {
              ForEach(0 ..< self.vehicles.count) { index in
                Text(String(self.vehicles[index].name ?? "--")).tag(index)
              }
            }.onChange(of: selectedVehicleIndex, perform: handleSelectVehicleChange)
          }
          Divider()
        }
        
        Toggle("Use original readings to draw the line chart",
               isOn: $lineChartShowOriginalData)
        Divider()
        
        Button(action: handleRate) {
          Text("Rate Leastimator").foregroundColor(.mainText)
        }
        Divider()
        
        Button(action: handleSupport) {
          Text("Support").foregroundColor(.mainText)
        }
        Divider()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
          Text("Current version: \(version)")
          Divider()
        }
        
        
        Spacer()
      }  // VStack
      .padding(10.0)
      .navigationBarTitle("Settings", displayMode: .inline)
      .navigationBarItems(
        leading:
          Button(action: { self.onDismiss() }) {
            Image(systemName: "xmark")
          }
      )
    }
  }
  
  private func handleRate() {
    if let url = URL(string: "itms-apps://apple.com/app/id1228501014") {
      UIApplication.shared.open(url)
    }
  }
  
  private func handleSupport() {
    if let url = URL(string: "mailto:liuhao1990@gmail.com?subject=%5BNeed%20Help%20for%20Leastimator%5D&body=Hi%20Leastimator%20developer%2C%0D%0A%0D%0A") {
      UIApplication.shared.open(url)
    }
  }
  
  private func handleSelectVehicleChange(index: Int) {
    for vehicle in vehicles {
      vehicle.showOnWidget = false
    }
    vehicles[index].showOnWidget = true
    
    do {
      try viewContext.save()
    } catch {
      print(error)
    }
    WidgetCenter.shared.reloadAllTimelines()
  }
}
