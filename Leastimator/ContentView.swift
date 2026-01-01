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
  var width: CGFloat = 80.0
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
  @State private var redirectToSettings = false
  @State private var showAddVehicleSheet = false
  @State private var showEditVehicleSheet: Vehicle?
  @State private var showReadingListSheet: Vehicle?
  @State private var showVehicleReadingHistorySheet = false
  @State private var showProProductSheet = false
  
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
  
  private var vehicleToDisplay: Vehicle? {
    if !vehicles.isEmpty {
      let vehicleShouldShow = vehicles.filter { $0.showOnStart }.first
      return vehicleShouldShow ?? vehicles.first
    }
    return nil
  }
  
  // Subtitle shown under the navigation title when available (iOS 26+)
  private var navigationSubtitle: String? {
    vehicleToDisplay?.leaseSubtitle
  }

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(colors: [Color("LessBlack"), Color.black],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
        
        VStack {
          if vehicles.isEmpty {
            Spacer()
            Button {
              showAddVehicleSheet.toggle()
            } label: {
              ZStack {
                HStack(alignment: .center) {
                  Image("CarCover")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320.0)
                }
                PlusGrayCircle()
                  .opacity(0.8)
              }
            }
            Text("Add Vehicle")
              .font(.system(.title3, design: .rounded))
            Spacer()
          } else {
            if let vehicle = vehicleToDisplay {
              VehiclePresentation(vehicle: vehicle)
            }
          }
        }  // VStack
        .navigationTitle(vehicleToDisplay?.name ?? "")
        .applyNavigationSubtitle(navigationSubtitle)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Menu {
              ForEach(vehicles) { vehicle in
                Button {
                  if purchaseManager.unlockPro {
                    for vehicle in vehicles {
                      vehicle.showOnStart = false
                    }
                    vehicle.showOnStart = true
                    try? viewContext.save()
                  } else if vehicle != vehicleToDisplay {
                    showProProductSheet.toggle()
                  }
                } label: {
                  Text(vehicle.name ?? kUnknownVehicleName)
                  Spacer()
                  if vehicle == vehicleToDisplay {
                    Image(systemName: "checkmark")
                  } else if !purchaseManager.unlockPro {
                    Image(systemName: "lock.fill")
                  }
                }
              }
              Divider()
              Button { redirectToSettings.toggle() } label: {
                Label("Settings", systemImage: "gearshape.2")
              }
              Button { showAddVehicleSheet.toggle() } label: {
                Label("Add Vehicle", systemImage: "plus")
              }
            } label: {
              Label("Vehicles", systemImage: "car.side")
            }
          }
          if let vehicle = vehicleToDisplay {
            ToolbarItem(placement: .secondaryAction) {
              Button {
                showEditVehicleSheet = vehicle
              } label: {
                Label("Edit Vehicle", systemImage: "slider.horizontal.3")
              }
              
            }
            ToolbarItem(placement: .secondaryAction) {
              Button {
                vehicle.archived.toggle()
                try? viewContext.save()
              } label: {
                Label(vehicle.archived ? "Unarchive" : "Archive",
                      systemImage: vehicle.archived ? "archivebox.fill" : "archivebox")
              }
            }
            ToolbarItem(placement: .secondaryAction) {
              Button {
                showReadingListSheet = vehicle
              } label: {
                Label("Odometer History", systemImage: "calendar.badge.clock")
              }
            }
          }
        }
        .navigationDestination(isPresented: $redirectToSettings) {
          SettingsView(vehicles: vehicles)
            .navigationBarTitle("Settings", displayMode: .inline)
        }
        .sheet(isPresented: $showProProductSheet) {
          ProProductsView()
            .withErrorHandler()
            .navigationBarTitle("Leastimator Pro", displayMode: .inline)
        }
        .sheet(isPresented: $showAddVehicleSheet) {
          EditVehicleView()
            .withErrorHandler()
        }
        .sheet(item: $showEditVehicleSheet) {
          EditVehicleView(vehicle: $0)
            .withErrorHandler()
        }
        .sheet(item: $showReadingListSheet) {
          ReadingList(vehicle: $0)
        }
      }
    }
    // This line is critical to prevent purchase page from popping back.
    // https://developer.apple.com/forums/thread/693137
    .navigationViewStyle(.stack)
  }
}
