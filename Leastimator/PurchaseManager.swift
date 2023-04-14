//
//  PurchaseManager.swift
//  Leastimator
//
//  Created by Hao Liu on 3/10/23.
//

import Foundation
import StoreKit
import TPInAppReceipt

@MainActor
class PurchaseManager: ObservableObject {
  
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
  
  var unlockPro: Bool {
    return !self.purchasedProductIDs.isEmpty || self.isNonIAPPurchased
  }
  
  // Called on app start, check if there are already purchases made.
  func updatePurchasedProducts() async {
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
    if purchasedProductIDs.isEmpty {
      Logger.shared.userPlan(.Free)
    } else {
      Logger.shared.userPlan(.Pro)
    }
    checkForNonIAPPurchases()
  }
  
  // Check for non IAP purchases which were done when Leastimator was a paid app (build <= 51).
  private func checkForNonIAPPurchases() {
    do {
      // Check old receipt store locally and if found no need to check further.
      let isNonIAPPurchased = UserDefaults.standard.bool(forKey: "isNonIAPPurchased")
      if isNonIAPPurchased {
        self.isNonIAPPurchased = true
        Logger.shared.userPlan(.NonIAPPro)
        return
      }
      
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
        self.isNonIAPPurchased = true
        Logger.shared.userPlan(.NonIAPPro)
      }
      
    } catch {
      Logger.shared.appStoreReceiptNotFound()
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
        print(error)
        break
      case .pending:
        Logger.shared.proPending()
        // Transaction waiting on SCA (Strong Customer Authentication) or
        // approval from Ask to Buy
        break
      case .userCancelled:
        Logger.shared.proCanceled()
        print("User canceled a purchase")
        break
      @unknown default:
        break
    }
  }
}
