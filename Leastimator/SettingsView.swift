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
  @EnvironmentObject private var purchaseManager: PurchaseManager
  
  @AppStorage("enterVehicleViewOnStart") var enterVehicleViewOnStart: Bool = false
  
  var vehicles: FetchedResults<Vehicle>
  
  @State private var selectedVehicleOnWidgetIndex: Int
  @State private var selectedVehicleOnStartIndex: Int
  
  init(vehicles: FetchedResults<Vehicle>) {
    self.vehicles = vehicles
    
    var initialVehicleOnWidgetIndex = -1
    var initialVehicleOnStartIndex = -1
    if vehicles.count > 0 {
      initialVehicleOnWidgetIndex = 0
      initialVehicleOnStartIndex = 0
    }
    for (index, vehicle) in vehicles.enumerated() {
      if vehicle.showOnWidget {
        initialVehicleOnWidgetIndex = index
      }
      if vehicle.showOnStart {
        initialVehicleOnStartIndex = index
      }
    }
    
    _selectedVehicleOnWidgetIndex = State(initialValue: initialVehicleOnWidgetIndex)
    _selectedVehicleOnStartIndex = State(initialValue: initialVehicleOnStartIndex)
  }
  
  var body: some View {
    List {
      Section {
        if vehicles.count > 0 {
          Picker("Vehicle in widget", selection: $selectedVehicleOnWidgetIndex) {
            ForEach(0 ..< self.vehicles.count, id: \.self) { index in
              Text(String(self.vehicles[index].name ?? "--")).tag(index)
            }
          }.onChange(of: selectedVehicleOnWidgetIndex, perform: handleSelectVehicleOnWidgetChange)
        }
        //        NavigationLink(destination: NotificationView().navigationTitle("Notifications")) {
        //          Text("Notifications").foregroundColor(.mainText)
        //        }
      } footer: {
        Text("Choose which vehicle to present in the main screen widget.")
      }
      
      Section {
        Toggle(isOn: $enterVehicleViewOnStart) {
          Text("Enter vehicle on start")
        }
        Picker("Start up vehicle", selection: $selectedVehicleOnStartIndex) {
          ForEach(0 ..< self.vehicles.count, id: \.self) { index in
            Text(String(self.vehicles[index].name ?? "--")).tag(index)
          }
        }
        .disabled(!enterVehicleViewOnStart)
        .onChange(of: selectedVehicleOnStartIndex, perform: handleSelectVehicleOnStartChange)
      } footer: {
        Text("When app starts, skip the list and present the vehicle information.")
      }
      
      Section {
        NavigationLink("Leastimator Pro", destination: ProProductsView().withErrorHandler().navigationBarTitle("Leastimator Pro", displayMode: .inline))
      }
      
      Section {
        Button(action: handleRate) {
          Text("Please rate Leastimator").foregroundColor(.mainText)
        }
        
        Button(action: handleSupport) {
          Text("Support").foregroundColor(.mainText)
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
          Text("Current version: \(version)")
        }
      }
      
      Section {
        Link("Privacy Policy", destination: URL(string: "https://liuhao.im/leastimator/pp")!)
        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
      }
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
  
  private func handleSelectVehicleOnWidgetChange(index: Int) {
    for vehicle in vehicles {
      vehicle.showOnWidget = false
    }
    vehicles[index].showOnWidget = true
    
    do {
      try viewContext.save()
    } catch {
      print(error)
    }
  }
  
  private func handleSelectVehicleOnStartChange(index: Int) {
    for vehicle in vehicles {
      vehicle.showOnStart = false
    }
    vehicles[index].showOnStart = true
    
    do {
      try viewContext.save()
    } catch {
      print(error)
    }
  }
}
