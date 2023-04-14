//
//  ContentView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import SwiftUI
import CoreData
import WidgetKit

struct PlusGrayCircle: View {
  var width: CGFloat = 100
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.subBg)
        .frame(width: width, height: width)
      Image(systemName: "plus")
        .resizable()
        .frame(width: width / 2, height: width / 2)
        .foregroundColor(.mainText)
    }
  }
}

struct ContentView: View {
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @Environment(\.managedObjectContext) private var viewContext
  @AppStorage("enterVehicleViewOnStart") var enterVehicleViewOnStart: Bool = false
  @State private var selectedVehicle: Vehicle? = nil
  @State private var redirectToProProduct = false
  @State private var redirectToVehicle = false
  @State private var redirectToSettings = false
  
  // TODO: deprecate this. Don't use environment object for this.
  @EnvironmentObject private var sheetStore: SheetStore
  
  @FetchRequest(
    entity: Vehicle.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.name, ascending: true)],
    predicate: NSPredicate(format: "removed == nil OR removed == false"))
  private var vehicles: FetchedResults<Vehicle>
  
  /// Get the vehicle which has showOnWidget turned on, or return the first vehicle in the list.
  private var vehicleOnWidget: Vehicle? {
    get {
      var vehicle: Vehicle?
      for veh in vehicles {
        if veh.showOnWidget {
          vehicle = veh
          break
        }
      }
      if vehicle == nil && vehicles.count > 0 {
        vehicle = vehicles[0]
      }
      return vehicle
    }
  }
  
  private func addVehicle() {
    if purchaseManager.unlockPro || vehicles.count < 1 {
      sheetStore.activeSheet = .vehicleCreation
    } else {
      redirectToProProduct = true
    }
  }
  
  var body: some View {
    NavigationStack {
      VStack {
        if vehicles.count == 0 {
          Button(action: addVehicle) {
            ZStack {
              Image("CarOutline")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 300)
                .accentColor(.subText)
                .opacity(0.4)
              PlusGrayCircle()
            }
          }
        } else {
          List {
            ForEach(Array(vehicles.enumerated()), id: \.offset) { index, vehicle in
              Button(action: {
                if !purchaseManager.unlockPro && index > 0 {
                  self.redirectToProProduct = true
                } else {
                  self.selectedVehicle = vehicle
                  self.redirectToVehicle = true
                }
              }) {
                VehicleRow(vehicle: vehicle)
              }
              .listRowSeparator(.hidden)
            }.navigationDestination(isPresented: $redirectToVehicle) {
              if let vehicle = self.selectedVehicle {
                VehiclePresentation(vehicle: vehicle)
              }
            }
            
            HStack {
              Button(action: addVehicle) {
                PlusGrayCircle(width: 64)
              }
              Spacer()
              if !purchaseManager.unlockPro {
                ProBadge()
              }
            }.listRowSeparator(.hidden)
            
          }
          .listStyle(.plain)
          .task {
            selectStartVehicle()
          }
        }
      }  // VStack
      .navigationDestination(isPresented: $redirectToProProduct) {
        ProProductsView()
          .withErrorHandler()
          .navigationBarTitle("Leastimator Pro", displayMode: .inline)
      }
      .task {
        Logger.shared.userVehicleCount(vehicles.count)
      }
      .navigationBarTitle(Text("My Garage"))
      .navigationBarItems(
        trailing:
          Button(action: { redirectToSettings = true }) {
            Image(systemName: "gearshape")
          }
      )
      .navigationDestination(isPresented: $redirectToSettings) {
        SettingsView(vehicles: vehicles).navigationBarTitle("Settings", displayMode: .inline)
      }
      .sheet(item: $sheetStore.activeSheet) { item in
        switch item {
          case .vehicleCreation:
            EditVehicleView(onDismiss: handleSheetDismiss,
                            onDeletion: {})
              .withErrorHandler()
          case .addReading:
            if let vehicle = vehicleOnWidget {
              EditReadingView(vehicle: vehicle, onDismiss: handleSheetDismiss)
                .environment(\.managedObjectContext, viewContext)
                .withErrorHandler()
            } else {
              // Fallback message.
              VStack {
                Text("No vehicle is added yet")
                  .padding(10.0)
                Button(action: handleSheetDismiss) {
                  Label("Add a Vehicle", systemImage: "plus")
                }
              }
            }
        }
      }
    }
    // This line is critical to prevent purchase page from popping back.
    // https://developer.apple.com/forums/thread/693137
    .navigationViewStyle(.stack)
  }
  
  private func handleSheetDismiss() {
    sheetStore.activeSheet = nil
  }
  
  private func selectStartVehicle() {
    if enterVehicleViewOnStart {
      for vehicle in vehicles {
        if vehicle.showOnStart {
          selectedVehicle = vehicle
          redirectToVehicle = true
          break
        }
      }
    }
  }
}
