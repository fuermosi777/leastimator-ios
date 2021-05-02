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
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
  }
}
