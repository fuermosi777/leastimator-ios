import Foundation
import UserNotifications
import AVFoundation
import CoreData

@MainActor
class NotificationManager: ObservableObject {
  @Published private(set) var permissionGranted = false

  private let periodicNotificationID = "leastimator.periodic.reminder"
  private let connectionNotificationID = "leastimator.connection.reminder"

  /// Used by contexts without SwiftUI environment access, namely the BGAppRefreshTask handler.
  static let shared = NotificationManager()

  init() {
    checkPermissions()
    setupAudioRouteObservation()
  }
  
  func checkPermissions() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      Task { @MainActor in
        if settings.authorizationStatus == .notDetermined {
          self.requestNotificationPermission()
        } else {
          self.permissionGranted = settings.authorizationStatus == .authorized
        }
      }
    }
  }
  
  func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
      Task { @MainActor in
        self.permissionGranted = success
      }
    }
  }
  
  // MARK: - Periodic Reminders
  
  func schedulePeriodicNotification(enabled: Bool, frequency: String, time: Date) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [periodicNotificationID])
    
    guard enabled && permissionGranted else { return }
    
    let content = UNMutableNotificationContent()
    content.title = NSLocalizedString("Time to record mileage!", comment: "")
    content.body = NSLocalizedString("A quick update keeps your lease tracking accurate.", comment: "")
    content.sound = .default
    
    let calendar = Calendar.current
    var dateComponents = calendar.dateComponents([.hour, .minute], from: time)
    
    switch frequency {
    case "daily":
      break
    case "weekly":
      // Use today's weekday as default or current
      dateComponents.weekday = calendar.component(.weekday, from: Date())
    case "monthly":
      dateComponents.day = 1
    default:
      break
    }
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: periodicNotificationID, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request)
  }
  
  // MARK: - Connection Detection (Bluetooth/CarPlay)
  
  private func setupAudioRouteObservation() {
    NotificationCenter.default.addObserver(
      forName: AVAudioSession.routeChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.handleAudioRouteChange(notification)
    }
  }
  
  private func handleAudioRouteChange(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }
    
    // Check when a new device hits (like getting into car)
    if reason == .newDeviceAvailable {
      let routeDescription = AVAudioSession.sharedInstance().currentRoute
      let isCarConnection = routeDescription.outputs.contains { port in
        port.portType == .carAudio || port.portType == .bluetoothHFP || port.portType == .bluetoothA2DP
      }
      
      if isCarConnection {
        updateConnectionCountAndNotify()
      }
    }
  }
  
  private func updateConnectionCountAndNotify() {
    let enabled = UserDefaults.standard.bool(forKey: "connectionRemindersEnabled")
    let threshold = UserDefaults.standard.integer(forKey: "connectionThreshold")
    
    guard enabled && threshold > 0 && permissionGranted else { return }
    
    var count = UserDefaults.standard.integer(forKey: "connectionCount")
    count += 1
    
    if count >= threshold {
      sendImmediateReminder()
      UserDefaults.standard.set(0, forKey: "connectionCount")
    } else {
      UserDefaults.standard.set(count, forKey: "connectionCount")
    }
  }
  
  private func sendImmediateReminder() {
    let content = UNMutableNotificationContent()
    content.title = NSLocalizedString("Driving detected!", comment: "")
    content.body = NSLocalizedString("Add a mileage reading to stay on track?", comment: "")
    content.sound = .default

    let request = UNNotificationRequest(identifier: connectionNotificationID, content: content, trigger: nil) // trigger: nil means immediate
    UNUserNotificationCenter.current().add(request)
  }

  // MARK: - Pace Alerts

  /// Fetches all live (non-removed) vehicles from `context` and evaluates each for pace alerts.
  /// Shared by the foreground trigger and the `BGAppRefreshTask` handler so both use the same query.
  func evaluateAndNotifyAllVehicles(context: NSManagedObjectContext) {
    let fetchRequest = NSFetchRequest<Vehicle>(entityName: "Vehicle")
    fetchRequest.predicate = NSPredicate(format: "removed == nil OR removed == false")
    guard let vehicles = try? context.fetch(fetchRequest), !vehicles.isEmpty else { return }
    evaluateAndNotify(vehicles: vehicles)
  }

  /// Evaluates every vehicle for a state-change worth notifying about and sends at most
  /// one notification per vehicle. Safe to call repeatedly (foreground activation, BGAppRefreshTask) —
  /// `PaceAlertEngine` enforces cooldowns/one-shot flags so repeat calls are no-ops until state changes.
  func evaluateAndNotify(vehicles: [Vehicle]) {
    guard permissionGranted else { return }
    guard UserDefaults.standard.bool(forKey: "paceAlertsEnabled") else { return }

    let warningsEnabled = UserDefaults.standard.bool(forKey: "paceAlertWarningsEnabled")
    let goodNewsEnabled = UserDefaults.standard.bool(forKey: "paceAlertGoodNewsEnabled")

    for vehicle in vehicles {
      guard let alert = PaceAlertEngine.evaluate(vehicle: vehicle) else { continue }
      if alert.isGoodNews {
        guard goodNewsEnabled else { continue }
      } else {
        guard warningsEnabled else { continue }
      }
      send(alert)
    }
  }

  private func send(_ alert: PaceAlert) {
    let content = UNMutableNotificationContent()
    content.title = alert.title
    content.body = alert.body
    content.sound = .default

    let identifier = "leastimator.pace.\(alert.vehicle.entityIdentifier).\(alert.kind)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)

    let activeAlert = ActiveVehicleAlert(kind: alert.kind, message: alert.body, isGoodNews: alert.isGoodNews)
    AlertStateStore.setActiveAlert(activeAlert, for: alert.vehicle.entityIdentifier)
  }
}
