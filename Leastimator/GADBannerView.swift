//
//  GADBannerView.swift
//  Leastimator
//
//  Created by Hao Liu on 3/19/23.
//

import SwiftUI
import GoogleMobileAds

// Delegate methods for receiving width update messages.

struct BannerView: UIViewControllerRepresentable  {
#if DEBUG
  private var adUnitID = "ca-app-pub-3940256099942544/2934735716"
#else
  private var adUnitID = "ca-app-pub-2170418007417966/3304580295"
#endif
  
  func makeUIViewController(context: Context) -> UIViewController {
    let view = GADBannerView(adSize: GADAdSizeBanner)
    
    let viewController = UIViewController()
    view.adUnitID = adUnitID
    view.rootViewController = viewController
    viewController.view.addSubview(view)
    viewController.view.frame = CGRect(origin: .zero, size: GADAdSizeBanner.size)
    view.load(GADRequest())
    
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct BannerAd:View{
  var body: some View{
    HStack{
      Spacer()
      BannerView()
      Spacer()
    }
  }
}
