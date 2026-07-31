//
//  GADBannerView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/19/23.
//

import SwiftUI
import GoogleMobileAds

// Delegate methods for receiving width update messages.

struct AdBannerView: UIViewControllerRepresentable {
#if DEBUG
  private var adUnitID = "ca-app-pub-3940256099942544/2934735716"
#else
  private var adUnitID = "ca-app-pub-2170418007417966/3304580295"
#endif

  var adWidth: CGFloat
  @Binding var adHeight: CGFloat

  init(adWidth: CGFloat, adHeight: Binding<CGFloat>) {
    self.adWidth = adWidth
    self._adHeight = adHeight
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()

    // Adaptive banner: taller than the old fixed 320x50 size and sized
    // to the available width, matching AdMob's recommended format.
    let adSize = currentOrientationAnchoredAdaptiveBanner(width: adWidth)

    let bannerView = BannerView(adSize: adSize)
    bannerView.adUnitID = adUnitID
    bannerView.rootViewController = viewController
    bannerView.delegate = context.coordinator

    viewController.view.addSubview(bannerView)

    bannerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bannerView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
      bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor)
    ])

    bannerView.load(Request())
    return viewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

  final class Coordinator: NSObject, BannerViewDelegate {
    let parent: AdBannerView

    init(_ parent: AdBannerView) {
      self.parent = parent
    }

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
      DispatchQueue.main.async {
        self.parent.adHeight = bannerView.adSize.size.height
      }
    }
  }
}

struct BannerAd: View {
  @State private var adHeight: CGFloat = 50

  // GeometryReader reports 0 on its first pass inside a VStack/ScrollView,
  // which would send AdMob a zero-width request that silently fails to
  // load. The screen width (minus the card's own horizontal insets) is
  // known immediately, so use that instead.
  private var adWidth: CGFloat {
    UIScreen.main.bounds.width - 64
  }

  var body: some View {
    HStack {
      Spacer()
      AdBannerView(adWidth: adWidth, adHeight: $adHeight)
        .frame(width: adWidth, height: adHeight)
      Spacer()
    }
    .padding(.vertical, 8)
    .background(Color.subBg.opacity(0.3))
    .cornerRadius(24)
    .overlay(
        RoundedRectangle(cornerRadius: 24)
            .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
    )
  }
}
