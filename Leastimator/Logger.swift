//
//  Loggings.swift
//  Leastimator
//
//  Created by Hao Liu on 2/11/23.
//

import Foundation
import Mixpanel

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
}
