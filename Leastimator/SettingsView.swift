//
//  SettingsView.swift
//  Leastimator
//
//  Created by Hao Liu on 4/11/21.
//

import SwiftUI

struct SettingsView: View {
  var onDismiss: () -> Void
  var body: some View {
    NavigationView {
      VStack(alignment: .leading, spacing: 10.0) {
        Button(action: handleRate) {
          Text("Rate Leastimator").foregroundColor(.mainText)
        }
        Divider()
        
        Button(action: handleSupport) {
          Text("Support").foregroundColor(.mainText)
        }
        Divider()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
          Text("Current version: \(version)")
          Divider()
        }
        
        
        Spacer()
      }  // VStack
      .padding(10.0)
      .navigationBarTitle("Settings", displayMode: .inline)
      .navigationBarItems(
        leading:
          Button(action: { self.onDismiss() }) {
            Image(systemName: "xmark")
          }
      )
    }
  }
  
  private func handleRate() {
    if let url = URL(string: "itms-apps://apple.com/app/id1228501014") {
      UIApplication.shared.open(url)
    }
  }
  
  private func handleSupport() {
    if let url = URL(string: "mailto:liuhao1990@gmail.com?subject=%5BNeed%20Help%20for%20Leastimator%5D&body=Hi%20Leastimator%20developer%2C%0D%0A%0D%0A") {
      UIApplication.shared.open(url)
    }
  }
}
