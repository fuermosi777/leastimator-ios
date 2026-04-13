# SwiftUI Localization Audit & Sync Skill (Project Local)

This workflow is specific to the Leastimator project and ensures all strings are localized correctly.

## Scope
- Files: All `.swift` files in the `Leastimator/` directory.
- Target: `de.lproj/Localizable.strings`.

## Execution Workflow

### 1. Identify Hardcoded Strings
Search for SwiftUI components that carry user-facing text:
```bash
grep -rE "Text\(|Label\(|Button\(|navigationTitle\(|navigationBarTitle\(|Picker\(" . --include="*.swift"
```

### 2. Verify Key Existence
Cross-reference found strings with `Leastimator/de.lproj/Localizable.strings`.
> [!IMPORTANT]
> SwiftUI keys are case-sensitive. "Add Vehicle" must have a matching "Add Vehicle" key in the `.strings` file.

### 3. Check Dynamic Content
Ensure interpolated strings like `Text("Version \(v)")` have matching template keys like `"Version %@" = "...";` in the localization files.

### 4. Categorized Updates
Group new translations into logical sections in the `.strings` file:
- UI Actions (Buttons, Labels)
- Navigation & Titles
- Descriptions & Informational Text
- Pro Features & Analytics
- Units & Currencies
