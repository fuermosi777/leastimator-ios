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

## Technologies Used:©
*   **Language:** Swift
*   **UI Framework:** SwiftUI
*   **Data Persistence:** CoreData with CloudKit
*   **Dependency Management:** Swift Package Manager

## External Dependencies (Swift Packages):
*   `TPInAppReceipt`: For in-app purchase receipt validation.
*   `mixpanel-swift`: For analytics integration.
*   `SwiftRater`: For prompting users to rate the app.
*   `swift-package-manager-google-mobile-ads`: For integrating Google Mobile Ads.
