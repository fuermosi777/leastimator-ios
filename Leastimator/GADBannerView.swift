//
//  GADBannerView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/19/23.
//

import SwiftUI
import GoogleMobileAds

// Delegate methods for receiving width update messages.

struct AdBannerView: UIViewControllerRepresentable  {
#if DEBUG
  private var adUnitID = "ca-app-pub-3940256099942544/2934735716"
#else
  private var adUnitID = "ca-app-pub-2170418007417966/3304580295"
#endif
  
  func makeUIViewController(context: Context) -> UIViewController {
          let viewController = UIViewController()
          
          // Use the SDK's BannerView class (formerly GADBannerView)
          // AdSizeBanner is the new name for GADAdSizeBanner
          let bannerView = BannerView(adSize: AdSizeBanner)
          
          bannerView.adUnitID = adUnitID
          bannerView.rootViewController = viewController
          
          viewController.view.addSubview(bannerView)
          
          // Use Auto Layout for better sizing in 2026
          bannerView.translatesAutoresizingMaskIntoConstraints = false
          NSLayoutConstraint.activate([
              bannerView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
              bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor)
          ])
          
          bannerView.load(Request()) // GADRequest is now just Request
          return viewController
      }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct BannerAd:View{
  var body: some View{
    HStack{
      Spacer()
      AdBannerView()
      Spacer()
    }
  }
}
