//
//  ProProductsView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/9/23.
//

import SwiftUI
import StoreKit

struct ProProductsView: View {
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @EnvironmentObject var errorHandler: ErrorHandler
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      List {
        Section {} footer: {
          Text("Leastimator Pro is an optional subscription to control ads, track multiple vehicles, handle customization, and support future development")
            .font(.title3)
        }
        Section {
          if purchaseManager.isNonIAPPurchased {
            Text("🥳 Leastimator is a free app now. Thank you for purchasing and supporting Leastimator app before. You can enjoy Leastimator Pro for free.")
          } else if purchaseManager.unlockPro {
            Text("🥳 Thank you for supporting Leastimator by subscribing pro!")
          } else {
            ForEach(purchaseManager.products) { product in
              Button(action: {
                Task {
                  do {
                    try await purchaseManager.purchase(product)
                  } catch {
                    self.errorHandler.handle(error)
                  }
                }
              }) {
                HStack {
                  Text("\(product.displayName)").foregroundColor(.mainText)
                  Spacer()
                  Text("\(product.displayPriceWithPeriod)").foregroundColor(.mainText)
                }
              }
            }
          }
          
          Button(action: {
            Task {
              do {
                purchaseManager.reset()
                try await AppStore.sync()
              } catch {
                print(error)
              }
            }
          }) {
            Text("Restore Previous Purchases")
          }
        } footer: {
          Text("Leastimator Pro subscription can be shared by everyone in a family group.")
        }
        
        Section {
          Link("Privacy Policy", destination: URL(string: "https://liuhao.im/leastimator/pp")!)
          Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        }
      }
      .navigationTitle("Leastimator Pro")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        do {
          try await purchaseManager.loadProducts()
        } catch {
          self.errorHandler.handle(error)
        }
      }
    }
  }
}

