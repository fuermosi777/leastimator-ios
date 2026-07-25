//
//  Loggings.swift
//  Leastimator
//
//  Created by Hao Liu on 2/11/23.
//

import Foundation
import Mixpanel
import os

enum PlanForLogging: String {
  case Pro = "pro"
  case NonIAPPro = "non_iap_pro"
  case Free = "free"
}

final class Logger {
  static let shared = Logger()
  private var properties: [String: String]
  
  init() {
    Mixpanel.initialize(token: "57f0bccc53acbb1ea9b6b60f568eb0a3", trackAutomaticEvents: true)
    
    properties = [String: String]()
    properties["version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
#if DEBUG
    properties["env"] = "debug"
#else
    properties["env"] = "release"
#endif
    
    Mixpanel.mainInstance().identify(distinctId: Mixpanel.mainInstance().distinctId)
  }
  
  func appStart() {
    Mixpanel.mainInstance().track(event: "App Start", properties: properties)
  }
  
  func vehiclePageView() {
    Mixpanel.mainInstance().track(event: "Vehicle Page View", properties: properties)
  }
  
  func appStoreReceiptFound(_ originalBuildNumber: String) {
    var properties = properties
    properties["original_build"] = originalBuildNumber
    Mixpanel.mainInstance().track(event: "App Store Receipt Found", properties: properties)
  }
  
  func appStoreReceiptNotFound() {
    Mixpanel.mainInstance().track(event: "App Store Receipt Not Found", properties: properties)
  }
  
  func proSubscription() {
    Mixpanel.mainInstance().track(event: "Pro Subscription", properties: properties)
  }
  
  func proInvalid() {
    Mixpanel.mainInstance().track(event: "Pro invalid", properties: properties)
  }
  
  // User is trying to subscribe Pro but got pending status.
  func proPending() {
    Mixpanel.mainInstance().track(event: "Pro Pending", properties: properties)
  }
  
  // User canceled payment in last minute.
  func proCanceled() {
    Mixpanel.mainInstance().track(event: "Pro Canceled", properties: properties)
  }
  
  func userOriginalBuild(_ build: String) {
    Mixpanel.mainInstance().people.set(properties: [ "original_build": build ])
  }
  
  func userPlan(_ plan: PlanForLogging) {
    Mixpanel.mainInstance().people.set(properties: [ "plan": plan.rawValue ])
  }
  
  func userVehicleCount(_ count: Int) {
    Mixpanel.mainInstance().people.set(properties: [ "vehicle_count": String(count) ])
  }

  // MARK: - Paywall & conversion
  func proPaywallView() {
    Mixpanel.mainInstance().track(event: "Pro Paywall View", properties: properties)
  }

  func proPaywallBlocked(reason: String) {
    var props = properties
    props["reason"] = reason
    Mixpanel.mainInstance().track(event: "Pro Paywall Blocked", properties: props)
  }

  func proPlanSelected(plan: String) {
    var props = properties
    props["plan"] = plan
    Mixpanel.mainInstance().track(event: "Pro Plan Selected", properties: props)
  }

  // MARK: - Intents
  func readingLoggedViaIntent() {
    Mixpanel.mainInstance().track(event: "Reading Logged Via Intent", properties: properties)
    // An intent can run while the app is backgrounded, where the process may be
    // suspended before the queue drains on its own.
    Mixpanel.mainInstance().flush()
  }

  // MARK: - Vehicle lifecycle
  func vehicleCreated() {
    Mixpanel.mainInstance().track(event: "Vehicle Created", properties: properties)
  }

  func vehicleDeleted() {
    Mixpanel.mainInstance().track(event: "Vehicle Deleted", properties: properties)
  }

  // MARK: - Engagement
  func reminderEnabled(type: String, frequency: String? = nil) {
    var props = properties
    props["type"] = type
    if let frequency = frequency { props["frequency"] = frequency }
    Mixpanel.mainInstance().track(event: "Reminder Enabled", properties: props)
  }

  func rateAppTapped() {
    Mixpanel.mainInstance().track(event: "Rate App Tapped", properties: properties)
  }

  // MARK: - Tesla
  func teslaConnectSuccess(vehicleCount: Int) {
    var props = properties
    props["vehicle_count"] = String(vehicleCount)
    Mixpanel.mainInstance().track(event: "Tesla Connect Success", properties: props)
  }

  // Prefer the full technical detail (raw API bodies) for logging; users never
  // see this, only the friendly errorDescription.
  private func loggableDetail(_ error: Error) -> String {
    if let teslaError = error as? TeslaAuthError {
      return teslaError.debugDetail
    }
    return error.localizedDescription
  }

  func teslaAuthError(_ error: Error) {
    var props = properties
    props["error"] = loggableDetail(error)
    props["error_type"] = String(describing: type(of: error))
    Mixpanel.mainInstance().track(event: "Tesla Auth Error", properties: props)
  }

  func teslaAPIError(_ context: String, _ error: Error) {
    var props = properties
    props["context"] = context
    props["error"] = loggableDetail(error)
    Mixpanel.mainInstance().track(event: "Tesla API Error", properties: props)
  }

  func teslaSyncError(vehicleId: String, _ error: Error) {
    var props = properties
    props["vehicle_id"] = vehicleId
    props["error"] = loggableDetail(error)
    Mixpanel.mainInstance().track(event: "Tesla Sync Error", properties: props)
  }
}
