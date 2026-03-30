//
//  PottyTimeUITests.swift
//  PottyTimeUITests
//
//  Created by Allen Nguyen on 3/29/26.
//

import XCTest

// MARK: - Shared Onboarding Helper

/// Navigates through the full onboarding flow, handling system permission alerts.
func completeOnboardingIfPresent(app: XCUIApplication) {
    let letsGoButton = app.buttons["onboarding_letsGo"]
    guard letsGoButton.waitForExistence(timeout: 5) else { return }

    letsGoButton.tap()

    // Step 2: Accent Color — tap Continue
    let colorContinue = app.buttons["onboarding_continue_color"]
    guard colorContinue.waitForExistence(timeout: 5) else { return }
    colorContinue.tap()

    // Step 3: Sign In — tap Skip
    let skipSignIn = app.buttons["onboarding_skipSignIn"]
    guard skipSignIn.waitForExistence(timeout: 5) else { return }
    skipSignIn.tap()

    // Step 4: Permissions — tap Continue (don't request any permissions)
    let permsContinue = app.buttons["onboarding_continue_permissions"]
    guard permsContinue.waitForExistence(timeout: 5) else { return }
    permsContinue.tap()

    // Step 5: Home Location
    // The Continue button is disabled unless location is captured OR location is denied.
    // In a fresh simulator, location is .notDetermined, so we trigger a permission
    // request to get it denied, which enables the Continue button.
    let locationContinue = app.buttons["onboarding_continue_location"]
    guard locationContinue.waitForExistence(timeout: 5) else { return }

    if !locationContinue.isEnabled {
        // Tap the "I'm Home" button to trigger location permission alert
        let homeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Home'")).firstMatch
        if homeButton.exists && homeButton.isHittable {
            homeButton.tap()
            // Give time for the system alert to appear, then tap app to trigger interruption monitor
            sleep(2)
            app.tap()
            sleep(1)
        }
    }

    // After denying location, Continue should be enabled
    if locationContinue.waitForExistence(timeout: 3) {
        locationContinue.tap()
    }

    // Step 6: Dog Profile — enter name and finish
    let dogNameField = app.textFields["onboarding_dogName"]
    guard dogNameField.waitForExistence(timeout: 5) else { return }
    dogNameField.tap()
    dogNameField.typeText("Buddy")

    let startButton = app.buttons["onboarding_startTracking"]
    guard startButton.waitForExistence(timeout: 5) else { return }
    startButton.tap()

    // Wait for dashboard to appear
    _ = app.staticTexts["PottyTime"].waitForExistence(timeout: 10)
}

/// Navigates through onboarding up to (but not past) the dog profile step.
func completeOnboardingUntilDogProfile(app: XCUIApplication) {
    let letsGoButton = app.buttons["onboarding_letsGo"]
    guard letsGoButton.waitForExistence(timeout: 5) else { return }
    letsGoButton.tap()

    let colorContinue = app.buttons["onboarding_continue_color"]
    guard colorContinue.waitForExistence(timeout: 5) else { return }
    colorContinue.tap()

    let skipSignIn = app.buttons["onboarding_skipSignIn"]
    guard skipSignIn.waitForExistence(timeout: 5) else { return }
    skipSignIn.tap()

    let permsContinue = app.buttons["onboarding_continue_permissions"]
    guard permsContinue.waitForExistence(timeout: 5) else { return }
    permsContinue.tap()

    let locationContinue = app.buttons["onboarding_continue_location"]
    guard locationContinue.waitForExistence(timeout: 5) else { return }

    if !locationContinue.isEnabled {
        let homeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Home'")).firstMatch
        if homeButton.exists && homeButton.isHittable {
            homeButton.tap()
            sleep(2)
            app.tap()
            sleep(1)
        }
    }

    if locationContinue.waitForExistence(timeout: 3) {
        locationContinue.tap()
    }
}

// MARK: - Base Test Class

/// Base class that sets up the app with system alert handling and fresh state.
class PottyTimeUITestBase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-for-testing"]

        // Auto-dismiss system permission alerts (location, notifications)
        addUIInterruptionMonitor(withDescription: "System Alert") { alert in
            let dontAllow = alert.buttons["Don't Allow"]
            if dontAllow.exists {
                dontAllow.tap()
                return true
            }
            let ok = alert.buttons["OK"]
            if ok.exists {
                ok.tap()
                return true
            }
            let allow = alert.buttons["Allow"]
            if allow.exists {
                allow.tap()
                return true
            }
            return false
        }

        app.launch()
    }
}

/// Base class for tests that need onboarding completed first.
class PottyTimePostOnboardingTestBase: PottyTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboardingIfPresent(app: app)
    }
}

// MARK: - Onboarding Tests

final class OnboardingUITests: PottyTimeUITestBase {

    // MARK: - Welcome Screen

    @MainActor
    func testWelcomeScreenDisplaysAppName() throws {
        let title = app.staticTexts["PottyTime"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "App title should appear on welcome screen")
    }

    @MainActor
    func testWelcomeScreenHasLetsGoButton() throws {
        let button = app.buttons["onboarding_letsGo"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Let's Go button should exist")
    }

    // MARK: - Full Onboarding Flow

    @MainActor
    func testCompleteOnboardingFlow() throws {
        let letsGoButton = app.buttons["onboarding_letsGo"]
        XCTAssertTrue(letsGoButton.waitForExistence(timeout: 5))
        letsGoButton.tap()

        let colorContinue = app.buttons["onboarding_continue_color"]
        XCTAssertTrue(colorContinue.waitForExistence(timeout: 5), "Accent color screen should appear")
        colorContinue.tap()

        let skipSignIn = app.buttons["onboarding_skipSignIn"]
        XCTAssertTrue(skipSignIn.waitForExistence(timeout: 5), "Sign-in screen should appear")
        skipSignIn.tap()

        let permsContinue = app.buttons["onboarding_continue_permissions"]
        XCTAssertTrue(permsContinue.waitForExistence(timeout: 5), "Permissions screen should appear")
        permsContinue.tap()

        let locationContinue = app.buttons["onboarding_continue_location"]
        XCTAssertTrue(locationContinue.waitForExistence(timeout: 5), "Home location screen should appear")

        if !locationContinue.isEnabled {
            let homeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Home'")).firstMatch
            if homeButton.exists && homeButton.isHittable {
                homeButton.tap()
                sleep(2)
                app.tap()
                sleep(1)
            }
        }
        locationContinue.tap()

        let dogNameField = app.textFields["onboarding_dogName"]
        XCTAssertTrue(dogNameField.waitForExistence(timeout: 5), "Dog profile screen should appear")
        dogNameField.tap()
        dogNameField.typeText("Buddy")

        let startTrackingButton = app.buttons["onboarding_startTracking"]
        XCTAssertTrue(startTrackingButton.isEnabled, "Start Tracking should be enabled after entering name")
        startTrackingButton.tap()

        let dashboardTitle = app.staticTexts["PottyTime"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 10), "Dashboard should appear after onboarding")
    }

    // MARK: - Onboarding Navigation

    @MainActor
    func testDogProfileRequiresName() throws {
        completeOnboardingUntilDogProfile(app: app)

        let startButton = app.buttons["onboarding_startTracking"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertFalse(startButton.isEnabled, "Start Tracking should be disabled without a name")
    }

    @MainActor
    func testDogProfileSkipForHousehold() throws {
        completeOnboardingUntilDogProfile(app: app)

        // The skip option is a Button containing "I'm joining a household — skip this"
        // Search both buttons and static texts since SwiftUI may represent it as either
        let skipButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'skip'")).firstMatch
        let skipText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'skip'")).firstMatch

        if !skipButton.exists && !skipText.exists {
            app.swipeUp()
        }

        let found = skipButton.waitForExistence(timeout: 5) || skipText.waitForExistence(timeout: 2)
        XCTAssertTrue(found, "Skip option should exist for household joiners")
    }
}

// MARK: - Dashboard Tests

final class DashboardUITests: PottyTimePostOnboardingTestBase {

    @MainActor
    func testDashboardShowsDogName() throws {
        let dogGreeting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Hi,'")).firstMatch
        XCTAssertTrue(dogGreeting.waitForExistence(timeout: 10), "Dashboard should show dog greeting")
    }

    @MainActor
    func testDashboardFABExists() throws {
        let fab = app.buttons["dashboard_logButton"]
        XCTAssertTrue(fab.waitForExistence(timeout: 10), "FAB (+) button should exist on dashboard")
    }

    @MainActor
    func testFABOpensQuickLogSheet() throws {
        let fab = app.buttons["dashboard_logButton"]
        XCTAssertTrue(fab.waitForExistence(timeout: 10))
        fab.tap()

        // QuickTypeButton uses .onTapGesture so it appears as a generic element
        let peeButton = app.descendants(matching: .any).matching(identifier: "quickLog_pee").firstMatch
        let poopButton = app.descendants(matching: .any).matching(identifier: "quickLog_poop").firstMatch
        XCTAssertTrue(peeButton.waitForExistence(timeout: 5), "Pee button should appear in quick log")
        XCTAssertTrue(poopButton.exists, "Poop button should appear in quick log")
    }

    @MainActor
    func testQuickLogPeeAndConfirmation() throws {
        let fab = app.buttons["dashboard_logButton"]
        XCTAssertTrue(fab.waitForExistence(timeout: 10))
        fab.tap()

        let peeButton = app.descendants(matching: .any).matching(identifier: "quickLog_pee").firstMatch
        XCTAssertTrue(peeButton.waitForExistence(timeout: 5))
        peeButton.tap()

        // Handle potential location warning alert
        let alertOK = app.alerts.buttons["OK"]
        if alertOK.waitForExistence(timeout: 2) {
            alertOK.tap()
        }

        // Wait for sheet to dismiss or confirmation to appear
        sleep(2)

        // The FAB should reappear on dashboard after the sheet dismisses
        let fabAgain = app.buttons["dashboard_logButton"]
        XCTAssertTrue(fabAgain.waitForExistence(timeout: 10), "Dashboard should be visible after logging")
    }

    @MainActor
    func testQuickLogAllTypes() throws {
        let types = ["pee", "poop", "both", "accident"]

        for type in types {
            let fab = app.buttons["dashboard_logButton"]
            XCTAssertTrue(fab.waitForExistence(timeout: 10))
            fab.tap()

            let typeButton = app.descendants(matching: .any).matching(identifier: "quickLog_\(type)").firstMatch
            XCTAssertTrue(typeButton.waitForExistence(timeout: 5), "\(type) button should exist")
            typeButton.tap()

            // Handle potential location warning alert
            let alertOK = app.alerts.buttons["OK"]
            if alertOK.waitForExistence(timeout: 2) {
                alertOK.tap()
            }

            // Wait for sheet to dismiss
            sleep(2)
        }
    }

    @MainActor
    func testQuickLogLongPressShowsDetails() throws {
        let fab = app.buttons["dashboard_logButton"]
        XCTAssertTrue(fab.waitForExistence(timeout: 10))
        fab.tap()

        let peeButton = app.descendants(matching: .any).matching(identifier: "quickLog_pee").firstMatch
        XCTAssertTrue(peeButton.waitForExistence(timeout: 5))
        peeButton.press(forDuration: 1.5)

        // The "Add Details" is the navigation title — check both static texts and nav bars
        let addDetailsNav = app.navigationBars["Add Details"]
        let addDetailsText = app.staticTexts["Add Details"]
        let found = addDetailsNav.waitForExistence(timeout: 5) || addDetailsText.waitForExistence(timeout: 2)
        XCTAssertTrue(found, "Add Details view should appear on long press")

        let noteField = app.textFields["quickLog_noteField"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 3), "Note field should be visible")
    }

    @MainActor
    func testQuickLogWithNote() throws {
        let fab = app.buttons["dashboard_logButton"]
        XCTAssertTrue(fab.waitForExistence(timeout: 10))
        fab.tap()

        let poopButton = app.descendants(matching: .any).matching(identifier: "quickLog_poop").firstMatch
        XCTAssertTrue(poopButton.waitForExistence(timeout: 5))
        poopButton.press(forDuration: 1.5)

        let addDetailsNav = app.navigationBars["Add Details"]
        let addDetailsText = app.staticTexts["Add Details"]
        let found = addDetailsNav.waitForExistence(timeout: 5) || addDetailsText.waitForExistence(timeout: 2)
        XCTAssertTrue(found, "Add Details view should appear on long press")

        let noteField = app.textFields["quickLog_noteField"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 3))
        noteField.tap()
        noteField.typeText("Test note from UI test")

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()

        // Handle potential location warning alert
        let alertOK = app.alerts.buttons["OK"]
        if alertOK.waitForExistence(timeout: 2) {
            alertOK.tap()
        }

        sleep(2)

        // Dashboard should be visible after save
        let fabAgain = app.buttons["dashboard_logButton"]
        XCTAssertTrue(fabAgain.waitForExistence(timeout: 10), "Dashboard should be visible after saving")
    }
}

// MARK: - Tab Navigation Tests

final class TabNavigationUITests: PottyTimePostOnboardingTestBase {

    @MainActor
    func testTabBarExists() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist after onboarding")
    }

    @MainActor
    func testNavigateToHistoryTab() throws {
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
        historyTab.tap()

        let historyTitle = app.navigationBars["History"]
        XCTAssertTrue(historyTitle.waitForExistence(timeout: 5), "History view should appear")
    }

    @MainActor
    func testNavigateToMapTab() throws {
        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 10))
        mapTab.tap()

        sleep(2) // Allow map to load
        XCTAssertTrue(mapTab.isSelected, "Map tab should be selected")
    }

    @MainActor
    func testNavigateToSettingsTab() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        let dogProfileHeader = app.staticTexts["Dog Profile"]
        let dogProfilesHeader = app.staticTexts["Dog Profiles"]
        let found = dogProfileHeader.waitForExistence(timeout: 5) || dogProfilesHeader.waitForExistence(timeout: 2)
        XCTAssertTrue(found, "Settings should show dog profile section")
    }

    @MainActor
    func testNavigateBackToDashboard() throws {
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
        historyTab.tap()

        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()

        let dashboardTitle = app.staticTexts["PottyTime"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5), "Dashboard should appear when switching back")
    }

    @MainActor
    func testAllTabsAccessible() throws {
        let tabs = ["Home", "History", "Map", "Settings"]
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.waitForExistence(timeout: 10), "\(tabName) tab should exist")
            tab.tap()
            XCTAssertTrue(tab.isSelected, "\(tabName) tab should be selected after tap")
        }
    }
}

// MARK: - History Tests

final class HistoryUITests: PottyTimePostOnboardingTestBase {

    @MainActor
    func testHistoryShowsCalendar() throws {
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
        historyTab.tap()

        // History should show the navigation bar
        let historyTitle = app.navigationBars["History"]
        XCTAssertTrue(historyTitle.waitForExistence(timeout: 5), "History navigation bar should appear")
    }

    @MainActor
    func testHistoryShowsTodayHeader() throws {
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
        historyTab.tap()

        let todayHeader = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Today'")).firstMatch
        XCTAssertTrue(todayHeader.waitForExistence(timeout: 5), "Today's events header should appear")
    }

    @MainActor
    func testLogEventThenVerifyInHistory() throws {
        // Log an event from dashboard
        let fab = app.buttons["dashboard_logButton"]
        XCTAssertTrue(fab.waitForExistence(timeout: 10))
        fab.tap()

        let peeButton = app.descendants(matching: .any).matching(identifier: "quickLog_pee").firstMatch
        XCTAssertTrue(peeButton.waitForExistence(timeout: 5))
        peeButton.tap()

        // Handle potential location warning alert
        let alertOK = app.alerts.buttons["OK"]
        if alertOK.waitForExistence(timeout: 2) {
            alertOK.tap()
        }

        sleep(3)

        // Navigate to History
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
        historyTab.tap()

        // Verify event appears — look for any event row
        let eventRow = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'eventRow_'")).firstMatch
        XCTAssertTrue(eventRow.waitForExistence(timeout: 5), "Logged event should appear in History")
    }

    @MainActor
    func testHistoryHasExportButton() throws {
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10))
        historyTab.tap()

        sleep(2) // Allow view to settle

        // Export button (share icon) in toolbar
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Share'")).firstMatch
        XCTAssertTrue(exportButton.exists, "Export button should exist in History toolbar")
    }
}

// MARK: - Settings Tests

final class SettingsUITests: PottyTimePostOnboardingTestBase {

    @MainActor
    func testSettingsShowsDogProfile() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        let dogName = app.staticTexts["Buddy"]
        XCTAssertTrue(dogName.waitForExistence(timeout: 5), "Dog name should appear in Settings")
    }

    @MainActor
    func testSettingsShowsNotificationSection() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        let notifSection = app.staticTexts["Notifications"]
        XCTAssertTrue(notifSection.waitForExistence(timeout: 5), "Notifications section should appear")
    }

    @MainActor
    func testSettingsShowsLocationSection() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        // The section header is "Location", the row inside is "Location Access"
        let locationRow = app.staticTexts["Location Access"]
        app.swipeUp()
        XCTAssertTrue(locationRow.waitForExistence(timeout: 5), "Location Access row should appear in Settings")
    }

    @MainActor
    func testSettingsShowsHouseholdSection() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        let household = app.staticTexts["Household"]
        app.swipeUp()
        XCTAssertTrue(household.waitForExistence(timeout: 5), "Household section should appear")
    }

    @MainActor
    func testSettingsShowsThemePicker() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        app.swipeUp()

        let systemButton = app.buttons["System"]
        let darkButton = app.buttons["Dark"]
        let lightButton = app.buttons["Light"]

        let found = systemButton.waitForExistence(timeout: 5) || darkButton.waitForExistence(timeout: 2) || lightButton.waitForExistence(timeout: 2)
        XCTAssertTrue(found, "Theme picker should appear in Settings")
    }

    @MainActor
    func testSettingsAddDogButton() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        let addDogButton = app.buttons["Add Dog"]
        XCTAssertTrue(addDogButton.waitForExistence(timeout: 5), "Add Dog button should exist in Settings")
    }

    @MainActor
    func testSettingsNavigateToDogProfile() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        let dogCell = app.staticTexts["Buddy"]
        XCTAssertTrue(dogCell.waitForExistence(timeout: 5))
        dogCell.tap()

        let nameField = app.textFields.matching(NSPredicate(format: "value CONTAINS 'Buddy'")).firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Edit dog profile should show dog name")
    }
}
