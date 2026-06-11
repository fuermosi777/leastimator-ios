//
//  ProProductsView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/9/23.
//

import SwiftUI
import StoreKit

private struct FeatureRow: View {
  let icon: String
  let title: String
  let subtitle: String

  var body: some View {
    HStack(alignment: .center, spacing: 14) {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.accentColor.opacity(0.15))
          .frame(width: 40, height: 40)
        Image(systemName: icon)
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.accentColor)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.rounded(14, weight: .semibold))
          .foregroundColor(.mainText)
        Text(subtitle)
          .font(.rounded(12))
          .foregroundColor(.subText)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct PlanCard: View {
  let product: Product
  let isHighlighted: Bool
  let isSelected: Bool
  let onTap: () -> Void

  private var periodLabel: String {
    guard let sub = product.subscription else { return "" }
    return sub.subscriptionPeriod.unit == .year ? "Annual" : "Monthly"
  }

  private var savingsBadge: String? {
    guard let sub = product.subscription, sub.subscriptionPeriod.unit == .year else { return nil }
    return "Best Value"
  }

  var body: some View {
    Button(action: onTap) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 8) {
            Text(periodLabel)
              .font(.rounded(14, weight: .semibold))
              .foregroundColor(.mainText)
            if let badge = savingsBadge {
              Text(badge)
                .font(.rounded(10, weight: .bold))
                .foregroundColor(.accentColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Capsule())
            }
          }
          Text(product.displayPriceWithPeriod)
            .font(.rounded(12))
            .foregroundColor(.subText)
        }
        Spacer()
        ZStack {
          Circle()
            .strokeBorder(isSelected ? Color.accentColor : Color.subText.opacity(0.4), lineWidth: 2)
            .frame(width: 22, height: 22)
          if isSelected {
            Circle()
              .fill(Color.accentColor)
              .frame(width: 13, height: 13)
          }
        }
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 16)
      .background(Color.subBg)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
      )
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
  }
}

struct ProProductsView: View {
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @EnvironmentObject var errorHandler: ErrorHandler
  @Environment(\.dismiss) private var dismiss

  @State private var selectedProduct: Product?

  private let features: [(icon: String, title: String, subtitle: String)] = [
    ("car.2.fill",         "Multiple vehicles",   "Track every lease in one place."),
    ("bolt.fill",          "Tesla auto-sync",      "Readings pull in automatically."),
    ("chart.line.uptrend.xyaxis", "Deeper insights", "More stats, longer history."),
    ("rectangle.3.group.fill", "No ads",           "Clean, distraction-free experience."),
  ]

  private var yearlyProduct: Product? {
    purchaseManager.products.first { $0.id.contains("yearly") }
  }

  private var monthlyProduct: Product? {
    purchaseManager.products.first { $0.id.contains("monthly") }
  }

  var body: some View {
    ZStack(alignment: .top) {
      Color.mainBg.ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          // Header
          VStack(alignment: .leading, spacing: 10) {
            Text("LEASTIMATOR · PRO")
              .font(.system(size: 11, weight: .bold, design: .monospaced))
              .foregroundColor(.accentColor)
              .tracking(2)

            Text("Stay ahead of\nevery mile.")
              .font(.rounded(30, weight: .bold))
              .foregroundColor(.mainText)
              .lineSpacing(2)
          }
          .padding(.top, 60)
          .padding(.horizontal, 28)
          .padding(.bottom, 32)

          // Feature list
          VStack(spacing: 18) {
            ForEach(features, id: \.title) { f in
              FeatureRow(icon: f.icon, title: f.title, subtitle: f.subtitle)
            }
          }
          .padding(.horizontal, 28)
          .padding(.bottom, 36)

          if purchaseManager.isNonIAPPurchased || purchaseManager.unlockPro {
            // Already pro
            VStack(spacing: 8) {
              Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
              Text(purchaseManager.isNonIAPPurchased
                ? "Thank you for your early support — you have Pro for free."
                : "You're subscribed. Thanks for supporting Leastimator!")
                .font(.rounded(14))
                .foregroundColor(.subText)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
          } else {
            // Plan cards
            VStack(spacing: 10) {
              if let yearly = yearlyProduct {
                PlanCard(
                  product: yearly,
                  isHighlighted: true,
                  isSelected: selectedProduct?.id == yearly.id,
                  onTap: { selectedProduct = yearly; Logger.shared.proPlanSelected(plan: "yearly") }
                )
              }
              if let monthly = monthlyProduct {
                PlanCard(
                  product: monthly,
                  isHighlighted: false,
                  isSelected: selectedProduct?.id == monthly.id,
                  onTap: { selectedProduct = monthly; Logger.shared.proPlanSelected(plan: "monthly") }
                )
              }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Subscribe CTA
            Button {
              guard let product = selectedProduct else { return }
              Task {
                do {
                  try await purchaseManager.purchase(product)
                } catch {
                  errorHandler.handle(error)
                }
              }
            } label: {
              Text("Subscribe")
                .font(.rounded(16, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(selectedProduct != nil ? Color.accentColor : Color.accentColor.opacity(0.4))
                .clipShape(Capsule())
                .shadow(color: Color.accentColor.opacity(selectedProduct != nil ? 0.3 : 0), radius: 12, y: 4)
            }
            .disabled(selectedProduct == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Legal links
            HStack(spacing: 16) {
              Link("Privacy Policy", destination: URL(string: "https://liuhao.im/leastimator/pp")!)
              Text("·").foregroundColor(.subText)
              Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(.rounded(11))
            .foregroundColor(.subText)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)

            Text("Subscription renews automatically. Cancel anytime in App Store settings.")
              .font(.rounded(10))
              .foregroundColor(.subText.opacity(0.7))
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
              .padding(.horizontal, 28)
              .padding(.bottom, 32)
          }
        }
      }

      // Top bar: close (left) + restore (right)
      HStack {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.subText)
            .frame(width: 30, height: 30)
            .background(Color.subBg)
            .clipShape(Circle())
        }
        Spacer()
        if !purchaseManager.isNonIAPPurchased && !purchaseManager.unlockPro {
          Button {
            Task {
              purchaseManager.reset()
              try? await AppStore.sync()
            }
          } label: {
            Text("Restore")
              .font(.rounded(13))
              .foregroundColor(.subText)
          }
        }
      }
      .padding(.top, 16)
      .padding(.horizontal, 20)
    }
    .task {
      Logger.shared.proPaywallView()
      do {
        try await purchaseManager.loadProducts()
        if selectedProduct == nil {
          selectedProduct = yearlyProduct ?? purchaseManager.products.first
        }
      } catch {
        errorHandler.handle(error)
      }
    }
    .onChange(of: purchaseManager.products.count) { _ in
      if selectedProduct == nil {
        selectedProduct = yearlyProduct ?? purchaseManager.products.first
      }
    }
  }
}
