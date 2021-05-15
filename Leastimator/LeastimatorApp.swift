//
//  LeastimatorApp.swift
//  Leastimator
//
//  Created by Hao Liu on 3/13/21.
//

import SwiftUI
import SwiftRater

@main
struct LeastimatorApp: App {
  let persistenceController = PersistenceController.shared
  
  @StateObject private var sheetStore = SheetStore()
  @Environment(\.scenePhase) var phase
  
  
  init() {
    // Set inline navigation bar title to transparent.
    UINavigationBar.appearance().barTintColor = .clear
    UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
    UINavigationBar.appearance().shadowImage = UIImage()
    
    // Set up rater.
    SwiftRater.daysUntilPrompt = 10
    SwiftRater.usesUntilPrompt = 10
    SwiftRater.showLaterButton = true
    SwiftRater.daysBeforeReminding = 5
    // To use this, need to use SwiftRater.incrementSignificantUsageCount()
    // SwiftRater.significantUsesUntilPrompt = 3
    SwiftRater.debugMode = false
    SwiftRater.appLaunched()
  }
  
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .environmentObject(sheetStore)
        .onOpenURL { url in
          // Handle deep links.
          guard let deepLinkAction = url.deepLinkIdentifier else {
            return
          }
          switch deepLinkAction {
          case .addReading:
            sheetStore.activeSheet = .addReading
          }
        }
    }.onChange(of: phase) { (newPhase) in
      switch newPhase {
      case .active :
        guard let name = shortcutItemToProcess?.type else {
          return
        }
        // Defined in Info.plist
        if name == "AddReadingAction" {
          sheetStore.activeSheet = .addReading
        }
      case .inactive, .background:
        return
      @unknown default:
        return
      }
    }
  }
}

// For quick actions.
var shortcutItemToProcess: UIApplicationShortcutItem?

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    if let shortcutItem = options.shortcutItem {
      shortcutItemToProcess = shortcutItem
    }
    
    let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
    sceneConfiguration.delegateClass = CustomSceneDelegate.self
    
    return sceneConfiguration
  }
}

class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {
  func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    shortcutItemToProcess = shortcutItem
  }
}
