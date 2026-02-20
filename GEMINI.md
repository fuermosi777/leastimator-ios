# Leastimator Project Overview

The "Leastimator" project is an iOS application built with SwiftUI, designed to help users manage vehicle-related data, specifically focusing on mileage and other estimates. It features comprehensive vehicle management, odometer history tracking, and displays key information through a user-friendly interface. The application also includes a WidgetKit extension for quick access to vehicle data on the home screen.

## Key Features:
*   **Vehicle Management:** Add, edit, and display detailed vehicle information.
*   **Odometer History:** Track and view historical odometer readings.
*   **In-App Purchases:** Unlock "Pro" features through in-app purchases.
*   **Advertising:** Integrates Google Mobile Ads.
*   **Analytics:** Uses Mixpanel for application analytics.
*   **App Rating:** Prompts users for app ratings using SwiftRater.
*   **Cloud Synchronization:** Data persistence is handled via CoreData with CloudKit integration for seamless synchronization across devices.
*   **Unit and Currency Support:** Supports multiple units (miles/kilometers) and currencies (USD, CNY, EUR, GBP).
*   **Localization:** Available in English and German.
*   **WidgetKit Extension:** Provides a home screen widget for quick glances at vehicle information.

## Technologies Used:
*   **Language:** Swift
*   **UI Framework:** SwiftUI
*   **Data Persistence:** CoreData with CloudKit
*   **Dependency Management:** Swift Package Manager

## External Dependencies (Swift Packages):
*   `TPInAppReceipt`: For in-app purchase receipt validation.
*   `mixpanel-swift`: For analytics integration.
*   `SwiftRater`: For prompting users to rate the app.
*   `swift-package-manager-google-mobile-ads`: For integrating Google Mobile Ads.

## Building and Running the Project:

To build and run the Leastimator project, you will need Xcode installed on your macOS system.

1.  **Open in Xcode:** Navigate to the project directory and open `Leastimator.xcodeproj` in Xcode.
2.  **Select Target:**
    *   For the main application, select the `Leastimator` target.
    *   For the widget extension, select the `EstimateWidgetExtension` target.
3.  **Choose Destination:** Select your desired simulator or a connected iOS device.
4.  **Run:** Click the "Run" button (or press `Cmd + R`) in Xcode to build and deploy the application/widget.

## Development Conventions:

*   **Code Style:** Adheres to standard Swift coding conventions (e.g., camelCase for variables and functions, PascalCase for types).
*   **Extensions:** Functionality is often organized using Swift extensions (e.g., `Color+Extensions.swift`, `Date+Extensions.swift`) to keep code modular and readable.
*   **Localization:** All user-facing strings should be localized using `Localizable.strings` files, with support for English (`en.lproj`) and German (`de.lproj`).
*   **Deployment Target:** The main application targets iOS 17.0, and the Widget Extension targets iOS 16.4.
