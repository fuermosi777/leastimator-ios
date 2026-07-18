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
  @AppStorage("themePreference") private var themePreference = "dark"
  @AppStorage("periodicRemindersEnabled") private var periodicRemindersEnabled = false
  @AppStorage("reminderFrequency") private var reminderFrequency = "weekly"
  @AppStorage("reminderTime") private var reminderTime = Date().timeIntervalSince1970
  @AppStorage("connectionRemindersEnabled") private var connectionRemindersEnabled = false
  @AppStorage("connectionThreshold") private var connectionThreshold = 5
  @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
  @AppStorage("lastSyncTime") private var lastSyncTime: Double = 0
  
  @State private var showingRestartAlert = false
  @State private var showingICloudIneligibleAlert = false
  @State private var showProUpgradeSheet = false
  
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
      // 1. PREMIUM / PRO SECTION
      Section {
        if purchaseManager.unlockPro {
          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
              ZStack {
                Circle()
                  .fill(Color.statusAmber.opacity(0.15))
                  .frame(width: 40, height: 40)
                Image(systemName: "crown.fill")
                  .foregroundColor(.statusAmber)
                  .font(.system(size: 20))
              }
              VStack(alignment: .leading, spacing: 2) {
                Text("Leastimator Pro Active")
                  .font(.rounded(16, weight: .bold))
                  .foregroundColor(.mainText)
                Text("Thank you for supporting!")
                  .font(.rounded(12, weight: .medium))
                  .foregroundColor(.subText)
              }
              Spacer()
              Text("ACTIVE")
                .font(.rounded(11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.statusAmber)
                .cornerRadius(6)
            }
          }
          .padding(.vertical, 4)
        } else {
          Button {
            showProUpgradeSheet = true
          } label: {
            HStack(spacing: 12) {
              ZStack {
                Circle()
                  .fill(Color.statusAmber.opacity(0.15))
                  .frame(width: 40, height: 40)
                Image(systemName: "bolt.fill")
                  .foregroundColor(.statusAmber)
                  .font(.system(size: 20))
              }
              VStack(alignment: .leading, spacing: 4) {
                Text("Get Leastimator Pro")
                  .font(.rounded(16, weight: .bold))
                  .foregroundColor(.mainText)
                Text("Unlock iCloud sync, multi-vehicle tracking, custom gauges, and remove all ads.")
                  .font(.rounded(12))
                  .foregroundColor(.subText)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
            .padding(.vertical, 4)
          }
          .buttonStyle(.plain)
        }
      }
      
      // 2. PREFERENCES SECTION
      Section {
        // Vehicle in widget (only if vehicles count > 0)
        if vehicles.count > 0 {
          Picker(selection: $selectedVehicleOnWidgetIndex) {
            ForEach(0 ..< self.vehicles.count, id: \.self) { index in
              Text(String(self.vehicles[index].name ?? "--"))
                .tag(index)
            }
          } label: {
            Label {
              Text("Vehicle in widget")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "app.badge")
                .foregroundColor(.subText)
            }
          }
          .onChange(of: selectedVehicleOnWidgetIndex, perform: handleSelectVehicleOnWidgetChange)
        }
        
        // Mileage Variance Toggle
        Toggle(isOn: $showMileageVariance) {
          Label {
            Text("Show Mileage Variance")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "percent")
              .foregroundColor(.subText)
          }
        }
        
        // Theme Picker
        Picker(selection: $themePreference) {
          Text("System").tag("system")
          Text("Light").tag("light")
          Text("Dark").tag("dark")
        } label: {
          Label {
            Text("Theme")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "circle.lefthalf.filled")
              .foregroundColor(.subText)
          }
        }
      } header: {
        Text("Preferences")
      } footer: {
        Text("Configure widget settings and dashboard displays. Enabling variance displays your predicted mileage versus the allowed leased limit on the gauge.")
      }
      
      // 3. REMINDERS SECTION (Combining Periodic & Driving Reminders)
      Section {
        // Periodic Reminders
        Toggle(isOn: $periodicRemindersEnabled) {
          Label {
            Text("Periodic Reminders")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "bell.fill")
              .foregroundColor(.subText)
          }
        }
        if periodicRemindersEnabled {
          Picker(selection: $reminderFrequency) {
            Text("Daily").tag("daily")
            Text("Weekly").tag("weekly")
            Text("Monthly").tag("monthly")
          } label: {
            Label {
              Text("Frequency")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "calendar")
                .foregroundColor(.subText)
            }
          }
          DatePicker(selection: reminderTimeDate, displayedComponents: .hourAndMinute) {
            Label {
              Text("Reminder Time")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "clock")
                .foregroundColor(.subText)
            }
          }
        }
        
        // Driving Reminders
        Toggle(isOn: $connectionRemindersEnabled) {
          Label {
            Text("Driving Reminders")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "car.fill")
              .foregroundColor(.subText)
          }
        }
        if connectionRemindersEnabled {
          Stepper(value: $connectionThreshold, in: 1...20) {
            Label {
              Text("Every \(connectionThreshold) connections")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.subText)
            }
          }
        }
      } header: {
        Text("Reminders")
      } footer: {
        Text("Stay up to date. Schedule time-based reminders or get driving-based suggestions after connecting to your vehicle's Bluetooth/CarPlay.")
      }
      .onChange(of: periodicRemindersEnabled) { newValue in
        updatePeriodicNotification()
        if newValue { Logger.shared.reminderEnabled(type: "periodic", frequency: reminderFrequency) }
      }
      .onChange(of: reminderFrequency) { _ in updatePeriodicNotification() }
      .onChange(of: reminderTime) { _ in updatePeriodicNotification() }
      .onChange(of: connectionRemindersEnabled) { newValue in
        if newValue { Logger.shared.reminderEnabled(type: "driving") }
      }
      
      // 4. DATA & SYNC SECTION
      Section {
        // iCloud Sync
        Toggle(isOn: $iCloudSyncEnabled) {
          Label {
            Text("iCloud Sync")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "icloud.fill")
              .foregroundColor(.subText)
          }
        }
        .onChange(of: iCloudSyncEnabled) { newValue in
          if newValue {
            Task {
              let available = await ICloudManager.shared.checkICloudStatus()
              if !available {
                iCloudSyncEnabled = false
                showingICloudIneligibleAlert = true
              } else {
                showingRestartAlert = true
              }
            }
          } else {
            showingRestartAlert = true
          }
        }
        
        // Deleted Vehicles
        NavigationLink(destination: DeletedVehiclesView()) {
          Label {
            Text("Deleted Vehicles")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "trash")
              .foregroundColor(.subText)
          }
        }
      } header: {
        Text("Data & Cloud")
      } footer: {
        VStack(alignment: .leading, spacing: 4) {
          Text("Secure and sync your vehicle records. Access recently deleted vehicles to restore them if needed.")
          if iCloudSyncEnabled && lastSyncTime > 0 {
            Text("Last synced: \(formatSyncDate(Date(timeIntervalSince1970: lastSyncTime)))")
              .foregroundColor(.subText)
          }
        }
      }
      
      // 5. SUPPORT & LEGAL SECTION
      Section {
        Button(action: handleRate) {
          Label {
            Text("Please rate Leastimator")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "star.fill")
              .foregroundColor(.subText)
          }
        }
        
        Link(destination: URL(string: "https://x.com/leastimator")!) {
          Label {
            Text("Contact on X")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "at")
              .foregroundColor(.subText)
          }
        }
        
        Link(destination: URL(string: "https://liuhao.im/leastimator/pp")!) {
          Label {
            Text("Privacy Policy")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "lock.shield.fill")
              .foregroundColor(.subText)
          }
        }
        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
          Label {
            Text("Terms of Use")
              .foregroundColor(.mainText)
          } icon: {
            Image(systemName: "doc.text.fill")
              .foregroundColor(.subText)
          }
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
          HStack {
            Label {
              Text("Version")
                .foregroundColor(.mainText)
            } icon: {
              Image(systemName: "info.circle.fill")
                .foregroundColor(.subText)
            }
            Spacer()
            Text(version)
              .foregroundColor(.subText)
          }
        }
      } header: {
        Text("Support & Legal")
      }
    }
    .alert(isPresented: $showingRestartAlert) {
      Alert(
        title: Text("Restart Required"),
        message: Text("Please close and restart Leastimator to apply the iCloud sync changes."),
        dismissButton: .default(Text("OK"))
      )
    }
    .alert(isPresented: $showingICloudIneligibleAlert) {
      Alert(
        title: Text("iCloud Not Available"),
        message: Text("Please sign in to iCloud in your device settings to enable sync."),
        dismissButton: .default(Text("OK"))
      )
    }
    .sheet(isPresented: $showProUpgradeSheet) {
      ProProductsView()
        .withErrorHandler()
    }
  }

  private func handleRate() {
    Logger.shared.rateAppTapped()
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

  private func formatSyncDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func updatePeriodicNotification() {
    notificationManager.schedulePeriodicNotification(
      enabled: periodicRemindersEnabled,
      frequency: reminderFrequency,
      time: Date(timeIntervalSince1970: reminderTime)
    )
  }
}
