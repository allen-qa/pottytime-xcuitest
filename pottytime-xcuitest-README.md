# PottyTime XCUITest Suite

XCUITest UI automation tests for [PottyTime](https://apps.apple.com/app/pottytime), an iOS app for tracking dog potty events. Built with Swift and XCTest, targeting a SwiftUI + SwiftData app.

> **Note:** The app source code is private. This repo contains the test code only.

## Test Results

**31 tests passing** across 7 test classes

| Test Class | Tests | Coverage Area |
|---|---|---|
| `OnboardingUITests` | 5 | Welcome screen, full onboarding flow, dog profile validation, household skip |
| `DashboardUITests` | 7 | Dog greeting, FAB button, quick log sheet, all event types, long press details, notes |
| `TabNavigationUITests` | 6 | Tab bar presence, all 4 tabs accessible, navigation between tabs |
| `HistoryUITests` | 4 | Calendar view, today header, log-then-verify flow, export button |
| `SettingsUITests` | 7 | Dog profile, notifications, location, household, theme picker, add dog, profile navigation |
| `PottyTimeUITestsLaunchTests` | 2 | Launch screenshot capture, launch performance metrics |

## Architecture

### Base Classes

```
PottyTimeUITestBase            — Fresh app state + system alert handling
  └─ PottyTimePostOnboardingTestBase  — Completes onboarding in setUp
```

- **`PottyTimeUITestBase`**: Configures `XCUIApplication` with `--reset-for-testing` launch argument (wipes SwiftData stores for clean state), registers `addUIInterruptionMonitor` to auto-dismiss iOS permission dialogs (location, notifications)
- **`PottyTimePostOnboardingTestBase`**: Inherits from base, calls `completeOnboardingIfPresent()` in `setUp` so tests start from the main dashboard

### Shared Helpers

- **`completeOnboardingIfPresent(app:)`** — Navigates through all 6 onboarding steps: Welcome → Accent Color → Sign In (skip) → Permissions → Home Location → Dog Profile ("Buddy")
- **`completeOnboardingUntilDogProfile(app:)`** — Same flow but stops at the dog profile step (for testing that screen specifically)

### Key Patterns

**App state reset between test classes:**
```swift
app.launchArguments = ["--uitesting", "--reset-for-testing"]
```
The `--reset-for-testing` flag triggers a SwiftData wipe in the app's `init()`, ensuring each test class starts with fresh onboarding state.

**System permission alert handling:**
```swift
addUIInterruptionMonitor(withDescription: "System Alert") { alert in
    let dontAllow = alert.buttons["Don't Allow"]
    if dontAllow.exists { dontAllow.tap(); return true }
    // ... fallback for OK, Allow
}
```

**Home Location step workaround:**
The Continue button is disabled when location permission is `.notDetermined`. Tests tap the "I'm Home" button to trigger the permission dialog → interruption monitor denies it → `.denied` state enables the Continue button.

**Custom gesture views:**
The quick-log buttons use `.onTapGesture` + `.onLongPressGesture` (not SwiftUI `Button`), so they appear as generic elements in the accessibility tree:
```swift
// Can't use app.buttons["quickLog_pee"]
let peeButton = app.descendants(matching: .any)
    .matching(identifier: "quickLog_pee").firstMatch
```

**Long press gesture recognition:**
Combined `.onTapGesture` + `.onLongPressGesture(minimumDuration: 0.3)` requires a longer press duration in XCUITest to reliably trigger:
```swift
peeButton.press(forDuration: 1.5)  // 0.3s minimum + XCUITest overhead
```

**Location warning alerts:**
Location is denied during onboarding, so logging events triggers a "Location Unavailable" alert. Tests handle this with:
```swift
let alertOK = app.alerts.buttons["OK"]
if alertOK.waitForExistence(timeout: 2) { alertOK.tap() }
```

## Test Details

### Onboarding Tests (`OnboardingUITests`)

| Test | What it verifies |
|---|---|
| `testWelcomeScreenDisplaysAppName` | "PottyTime" title appears on launch |
| `testWelcomeScreenHasLetsGoButton` | "Let's Go" CTA button exists |
| `testCompleteOnboardingFlow` | Full 6-step flow completes and reaches dashboard |
| `testDogProfileRequiresName` | "Start Tracking" button is disabled without a dog name |
| `testDogProfileSkipForHousehold` | "Skip" option exists for users joining an existing household |

### Dashboard Tests (`DashboardUITests`)

| Test | What it verifies |
|---|---|
| `testDashboardShowsDogName` | Dog greeting ("Hi, Buddy") appears |
| `testDashboardFABExists` | Floating action button for logging exists |
| `testFABOpensQuickLogSheet` | FAB tap opens sheet with pee/poop buttons |
| `testQuickLogPeeAndConfirmation` | Tapping pee logs event, sheet dismisses, dashboard returns |
| `testQuickLogAllTypes` | All 4 event types (pee, poop, both, accident) can be logged |
| `testQuickLogLongPressShowsDetails` | Long press opens "Add Details" view with note field |
| `testQuickLogWithNote` | Long press → type note → save → returns to dashboard |

### Tab Navigation Tests (`TabNavigationUITests`)

| Test | What it verifies |
|---|---|
| `testTabBarExists` | Tab bar is present after onboarding |
| `testNavigateToHistoryTab` | History tab loads History view |
| `testNavigateToMapTab` | Map tab selects correctly |
| `testNavigateToSettingsTab` | Settings tab shows dog profile section |
| `testNavigateBackToDashboard` | Switching away and back to Home tab works |
| `testAllTabsAccessible` | All 4 tabs (Home, History, Map, Settings) are tappable and selectable |

### History Tests (`HistoryUITests`)

| Test | What it verifies |
|---|---|
| `testHistoryShowsCalendar` | History navigation bar appears |
| `testHistoryShowsTodayHeader` | "Today" section header is displayed |
| `testLogEventThenVerifyInHistory` | Log event on dashboard → navigate to History → event row appears |
| `testHistoryHasExportButton` | PDF export (Share) button exists in toolbar |

### Settings Tests (`SettingsUITests`)

| Test | What it verifies |
|---|---|
| `testSettingsShowsDogProfile` | Dog name "Buddy" appears in settings |
| `testSettingsShowsNotificationSection` | "Notifications" section header exists |
| `testSettingsShowsLocationSection` | "Location Access" row exists (with scroll) |
| `testSettingsShowsHouseholdSection` | "Household" section header exists |
| `testSettingsShowsThemePicker` | System/Dark/Light theme buttons appear |
| `testSettingsAddDogButton` | "Add Dog" button exists |
| `testSettingsNavigateToDogProfile` | Tapping dog name navigates to edit profile with name field |

## Files

```
PottyTimeUITests/
  PottyTimeUITests.swift              — 31 tests, 2 base classes, 2 shared helpers
  PottyTimeUITestsLaunchTests.swift   — Launch screenshot + performance tests
PottyTime.xctestplan                  — Test plan (sequential execution, single simulator)
```

## Tools & Frameworks

- **XCUITest** (XCTest UI Testing)
- **Swift 6**
- **Xcode 16**
- iOS Simulator (iPhone)
