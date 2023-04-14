//
//  ErrorHandler.swift
//  Leastimator
//
//  Created by Hao Liu on 3/10/23.
//

import SwiftUI

enum AppError: LocalizedError {
  case invalidInput(reason: String)
  case failedContextSave
  
  var errorDescription: String? {
    switch self {
      case .invalidInput(let reason):
        return String("Something is wrong with the information entered: \(reason)")
      case .failedContextSave:
        return String("Failed to save changes. Please close the app and try again")
    }
  }
}


struct ErrorAlert: Identifiable {
  var id = UUID()
  var message: String
  var dismissAction: (() -> Void)?
}

class ErrorHandler: ObservableObject {
  @Published var currentAlert: ErrorAlert?
  
  func handle(_ error: Error) {
    currentAlert = ErrorAlert(message: error.localizedDescription)
  }
}

struct HandleErrorsByShowingAlertViewModifier: ViewModifier {
  @StateObject var errorHandler = ErrorHandler()
  
  func body(content: Content) -> some View {
    content
      .environmentObject(errorHandler)
    // Applying the alert for error handling using a background element
    // is a workaround, if the alert would be applied directly,
    // other .alert modifiers inside of content would not work anymore
      .background(
        EmptyView()
          .alert(item: $errorHandler.currentAlert) { currentAlert in
            Alert(
              title: Text("Error"),
              message: Text(currentAlert.message),
              dismissButton: .default(Text("Ok")) {
                currentAlert.dismissAction?()
              }
            )
          }
      )
  }
}

extension View {
  func withErrorHandler() -> some View {
    modifier(HandleErrorsByShowingAlertViewModifier())
  }
}
