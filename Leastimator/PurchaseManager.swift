//
//  PurchaseManager.swift
//  Leastimator
//
//  Created by Hao Liu on 3/10/23.
//

import Foundation
import StoreKit
import TPInAppReceipt
import os

@MainActor
class PurchaseManager: ObservableObject {
  private let oslogger = os.Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: PurchaseManager.self)
  )
  
  private let productIds = ["leastimator_pro_monthly", "leastimator_pro_yearly"]
  
  @Published
  private(set) var purchasedProductIDs = Set<String>()
  
  @Published
  private(set) var products: [Product] = []
  private var productsLoaded = false
  // Monitoring changes outside of the app. E.g. subscription canceled, renewed, or revoked.
  private var updates: Task<Void, Never>? = nil
  var isNonIAPPurchased = false
  
  init() {
    updates = observeTransactionUpdates()
  }
  
  deinit {
    updates?.cancel()
  }
  
  // Used to determine if user is a pro.
  var unlockPro: Bool {
    // Check old receipt store locally and if found no need to check further.
    let isNonIAPPurchased = UserDefaults.standard.bool(forKey: "isNonIAPPurchased")
    if isNonIAPPurchased {
      self.isNonIAPPurchased = true
      Logger.shared.userPlan(.NonIAPPro)
      return true
    }
    
    let proStatus = UserDefaults.standard.bool(forKey: "proStatus")
    if proStatus {
      Logger.shared.userPlan(.Pro)
      return true
    }
    
    return !self.purchasedProductIDs.isEmpty || self.isNonIAPPurchased
  }
  
  // Called on app start, check if there are already purchases made.
  func updatePurchasedProducts() async {
    oslogger.trace("Update purchased products.")
    checkForNonIAPPurchases()
    if isNonIAPPurchased {
      return
    }
    
    let proStatus = UserDefaults.standard.bool(forKey: "proStatus")
    var proStatusUpdatedAt = UserDefaults.standard.object(forKey: "proStatusUpdatedAt") as! Date?
    if proStatusUpdatedAt == nil {
      proStatusUpdatedAt = Date()
    }
    let daysSince = Calendar.current.dateComponents([.day], from: proStatusUpdatedAt!, to: Date()).day!
    // No need to check if previous check is Pro and it was fewer than N days ago.
    if daysSince < 20 && proStatus {
      oslogger.trace("Pro status is fresh within 20 days, no need to check.")
      return
    }
    oslogger.trace("Check purchased products.")
    for await result in Transaction.currentEntitlements {
      guard case .verified(let transaction) = result else {
        continue
      }
      
      if transaction.revocationDate == nil {
        self.purchasedProductIDs.insert(transaction.productID)
      } else {
        self.purchasedProductIDs.remove(transaction.productID)
      }
    }
    // Update pro status in storage.
    if purchasedProductIDs.isEmpty {
      oslogger.notice("No purchased products, free user.")
      Logger.shared.userPlan(.Free)
      UserDefaults.standard.set(false, forKey: "proStatus")
      UserDefaults.standard.set(Date(), forKey: "proStatusUpdatedAt")
    } else {
      oslogger.notice("No purchased products, pro user.")
      Logger.shared.userPlan(.Pro)
      UserDefaults.standard.set(true, forKey: "proStatus")
      UserDefaults.standard.set(Date(), forKey: "proStatusUpdatedAt")
    }
  }
  
  // When user clicks "Restore purchases".
  func reset() {
    UserDefaults.standard.set(nil, forKey: "proStatusUpdatedAt")
    UserDefaults.standard.set(nil, forKey: "proStatus")
    UserDefaults.standard.set(nil, forKey: "isNonIAPPurchased")
  }
  
  // Check for non IAP purchases which were done when Leastimator was a paid app (build <= 51).
  private func checkForNonIAPPurchases() {
    oslogger.trace("Check for NonIAPP purchases.")
    do {
      /// Initialize receipt
      let receipt = try InAppReceipt.localReceipt()
      
      var originalAppVersion = receipt.originalAppVersion
      let buildSoldWithoutIAP = 51
      
      Logger.shared.appStoreReceiptFound(originalAppVersion)
      Logger.shared.userOriginalBuild(originalAppVersion)
      
      // Older versions use build like "2.1"
      originalAppVersion = originalAppVersion.replacingOccurrences(of: ".", with: "")
      
      let originalAppVersionInt = Int(originalAppVersion) ?? 52
      if originalAppVersionInt <= buildSoldWithoutIAP {
        // Identified a legacy paid user. Unlock all features.
        UserDefaults.standard.set(true, forKey: "isNonIAPPurchased")
        oslogger.notice("Found NonIAPP purchase history build.")
        self.isNonIAPPurchased = true
        Logger.shared.userPlan(.NonIAPPro)
      } else {
        oslogger.notice("Not a legacy paid user.")
      }
      
    } catch {
      Logger.shared.appStoreReceiptNotFound()
      oslogger.notice("Not found an app store receipt. Unable to detect legacy user or not.")
      print(error)
    }
  }
  
  private func observeTransactionUpdates() -> Task<Void, Never> {
    Task(priority: .background) { [unowned self] in
      for await verificationResult in Transaction.updates {
        // Using verificationResult directly would be better
        // but this way works for this tutorial
        print(verificationResult)
        await self.updatePurchasedProducts()
      }
    }
  }
  
  func loadProducts() async throws {
    guard !self.productsLoaded else { return }
    self.products = try await Product.products(for: productIds)
    self.productsLoaded = true
  }
  
  func purchase(_ product: Product) async throws {
    let result = try await product.purchase()
    
    switch result {
      case let .success(.verified(transaction)):
        // Successful purhcase
        Logger.shared.proSubscription()
        await transaction.finish()
        await self.updatePurchasedProducts()
      case let .success(.unverified(_, error)):
        // Successful purchase but transaction/receipt can't be verified
        // Could be a jailbroken phone
        Logger.shared.proInvalid()
        oslogger.error("Successful purchase but transaction/receipt can't be verified -- jailbroken?")
        break
      case .pending:
        Logger.shared.proPending()
        // Transaction waiting on SCA (Strong Customer Authentication) or
        // approval from Ask to Buy
        break
      case .userCancelled:
        Logger.shared.proCanceled()
        oslogger.warning("User canceled a purchase")
        break
      @unknown default:
        break
    }
  }
}
