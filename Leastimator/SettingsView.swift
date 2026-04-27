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
  @AppStorage("showMileageVariance") private var showMileageVariance = true
  @AppStorage("periodicRemindersEnabled") private var periodicRemindersEnabled = false
  @AppStorage("reminderFrequency") private var reminderFrequency = "weekly"
  @AppStorage("reminderTime") private var reminderTime = Date().timeIntervalSince1970
  @AppStorage("connectionRemindersEnabled") private var connectionRemindersEnabled = false
  @AppStorage("connectionThreshold") private var connectionThreshold = 5
  
  @EnvironmentObject private var notificationManager: NotificationManager
  
  var vehicles: FetchedResults<Vehicle>
  
  @State private var selectedVehicleOnWidgetIndex: Int
  
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
    }
    
    _selectedVehicleOnWidgetIndex = State(initialValue: initialVehicleOnWidgetIndex)
  }
  
  var body: some View {
    List {
      if vehicles.count > 0 {
        Section {
          Picker("Vehicle in widget", selection: $selectedVehicleOnWidgetIndex) {
            ForEach(0 ..< self.vehicles.count, id: \.self) { index in
              Text(String(self.vehicles[index].name ?? "--")).tag(index)
            }
          }.onChange(of: selectedVehicleOnWidgetIndex, perform: handleSelectVehicleOnWidgetChange)
          //        NavigationLink(destination: NotificationView().navigationTitle("Notifications")) {
          //          Text("Notifications").foregroundColor(.mainText)
          //        }
        } footer: {
          Text("Choose which vehicle to present in the main screen widget.")
        }
      }
      
      Section {
        Toggle(isOn: $showMileageVariance) {
          Text("Display Mileage Variance")
        }
      } footer: {
        Text("Emphasize the variance between actual and estimated mileage on vehicle display.")
      }
      
      Section {
        Toggle("Periodic Reminders", isOn: $periodicRemindersEnabled)
        if periodicRemindersEnabled {
          Picker("Frequency", selection: $reminderFrequency) {
            Text("Daily").tag("daily")
            Text("Weekly").tag("weekly")
            Text("Monthly").tag("monthly")
          }
          DatePicker("Reminder Time", selection: reminderTimeDate, displayedComponents: .hourAndMinute)
        }
      } header: {
        Text("Periodic Reminders")
      } footer: {
        Text("Get reminded to update your mileage on a schedule.")
      }
      .onChange(of: periodicRemindersEnabled) { _ in updatePeriodicNotification() }
      .onChange(of: reminderFrequency) { _ in updatePeriodicNotification() }
      .onChange(of: reminderTime) { _ in updatePeriodicNotification() }
      
      Section {
        Toggle("Driving Reminders", isOn: $connectionRemindersEnabled)
        if connectionRemindersEnabled {
          Stepper("Every \(connectionThreshold) connections", value: $connectionThreshold, in: 1...20)
        }
      } header: {
        Text("Driving Reminders")
      } footer: {
        Text("Get reminded after connecting to your car (Bluetooth/CarPlay) several times.")
      }
      
      Section {
        NavigationLink(destination: DeletedVehiclesView()) {
          Label("Deleted Vehicles", systemImage: "trash.slash")
        }
      } header: {
        Text("Data")
      } footer: {
        Text("View and restore vehicles that were previously deleted.")
      }

      Section {
        NavigationLink("Leastimator Pro", destination: ProProductsView().withErrorHandler().navigationBarTitle("Leastimator Pro", displayMode: .inline))
      }
      
      Section {
        Button(action: handleRate) {
          Text("Please rate Leastimator").foregroundColor(.mainText)
        }
        
        Link("Feedback", destination: URL(string: "https://github.com/fuermosi777/leastimator-feedback/issues")!)
        
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
  
  private func handleSelectVehicleOnWidgetChange(index: Int) {
    for vehicle in vehicles {
      vehicle.showOnWidget = false
    }
    vehicles[index].showOnWidget = true
    
    do {
      try viewContext.save()
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      print(error)
    }
  }

  private var reminderTimeDate: Binding<Date> {
    Binding(
      get: { Date(timeIntervalSince1970: reminderTime) },
      set: { reminderTime = $0.timeIntervalSince1970 }
    )
  }

  private func updatePeriodicNotification() {
    notificationManager.schedulePeriodicNotification(
      enabled: periodicRemindersEnabled,
      frequency: reminderFrequency,
      time: Date(timeIntervalSince1970: reminderTime)
    )
  }
}
