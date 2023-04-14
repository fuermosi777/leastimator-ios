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
  
  var body: some View {
    List {
      Text("Leastimator Pro is an optional subscription to control ads, add more than one vehicle, handling customization, and support future development")
      Section {
        if purchaseManager.isNonIAPPurchased {
          Text("Thank you for purchasing Leastimator app. You can enjoy Leastimator Pro for free.")
        } else if purchaseManager.unlockPro {
          Text("Thank you for supporting Leastimator by subscribing pro!")
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
                Text("\(product.displayPrice)").foregroundColor(.subText)
              }
            }
          }
        }
        
        Button(action: {
          Task {
            do {
              try await AppStore.sync()
            } catch {
              print(error)
            }
          }
        }) {
          Text("Restore Previous Purchases")
        }
      }
      
      Section {
        Link("Privacy Policy", destination: URL(string: "https://liuhao.im/leastimator/pp")!)
        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
      }
    }.task {
      do {
        try await purchaseManager.loadProducts()
      } catch {
        self.errorHandler.handle(error)
      }
    }
  }
}

