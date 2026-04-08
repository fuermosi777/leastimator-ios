# Leastimator Project Overview

An iOS app built with SwiftUI that helps users manage vehicle leases — tracking mileage, estimating overages, and displaying key stats via a home screen widget.

## Key Features
- Vehicle management (add, edit, display)
- Odometer history tracking
- Estimated mileage and overage charge calculation
- In-app purchases to unlock Pro features
- Google Mobile Ads integration
- Mixpanel analytics
- SwiftRater for app rating prompts
- CoreData + CloudKit for persistence and sync across devices
- Miles/km and USD/CNY/EUR/GBP support
- Localization: English and German
- WidgetKit home screen widget

## Tech Stack
- **Language:** Swift
- **UI:** SwiftUI
- **Data:** CoreData with CloudKit
- **Dependencies:** Swift Package Manager
  - `TPInAppReceipt` — in-app purchase receipt validation
  - `mixpanel-swift` — analytics
  - `SwiftRater` — app rating prompts
  - `swift-package-manager-google-mobile-ads` — ads

## Build & Run
Open `Leastimator.xcodeproj` in Xcode, select the `Leastimator` target (or `EstimateWidgetExtension` for the widget), choose a simulator or device, and press `Cmd+R`.

## Development Conventions
- **Code style:** Standard Swift — camelCase for variables/functions, PascalCase for types
- **Extensions:** Modular extensions in `Extensions/` (e.g. `Color+Extensions.swift`, `Date+Extensions.swift`)
- **Localization:** All user-facing strings go in `Localizable.strings` under `en.lproj` and `de.lproj`
- **Deployment targets:** Main app → iOS 17.0 · Widget extension → iOS 16.4
- **Don't add** error handling, fallbacks, or abstractions for hypothetical future use — keep it direct
- **Don't add** docstrings or comments to unchanged code
