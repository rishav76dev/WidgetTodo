# Todo1 for Android

Native Kotlin Android app, contained entirely in this folder. Open `android/` in Android Studio. The application ID and namespace are `com.widgettodo`; Kotlin files live directly in `app/src/main/kotlin/`.

## Build

Requires JDK 17 or 21, Android SDK 35, and Internet access for the first Gradle build. Android Studio installs the required SDK components. The Gradle wrapper is included.

```sh
cd android
./gradlew :app:assembleDebug :app:testDebugUnitTest :app:lintDebug
```

The installable debug APK is `app/build/outputs/apk/debug/app-debug.apk`.

## Included

- Add, edit, complete, reopen, and delete tasks, with a five-second delete undo.
- Notes, all-day dates, due times, and daily, weekday, weekly, monthly, or yearly recurrence.
- All and Today filters, custom lists, and Overdue / Today / Tomorrow / Upcoming / No date / Completed groups.
- All twelve original theme JSON definitions, bundled fonts and font licenses, previews, and three free themes (Paper, Midnight, Mono Mint).
- Local persistent storage, Android device backup, and completed-task cleanup after 30 days.
- Resizable home-screen widget with interactive completion, quick add, and independent list/theme settings through its ⋯ button.
- Notification permission handling, timed reminders, and rescheduling after reboot or timezone changes. Reminders use inexact alarms and can be delayed by Android battery management.
- `todo1://add`, `todo1://home?filter=today`, and `todo1://task/<id>` deep links.
- RevenueCat integration for Premium offerings, purchases, entitlement expiry, and restoring purchases.

## Google Play purchases

Supply the **public Android RevenueCat SDK key** through your user Gradle properties (never a secret API key):

```properties
revenueCatApiKey=goog_your_public_sdk_key
```

Configure this application ID in Google Play and RevenueCat, attach your Play products to the `premium` entitlement, and create a current offering with yearly and lifetime packages. Pricing and trial eligibility come from Google Play; this client does not hardcode them. Until configured, the three free themes work, and locked-theme actions explain that purchases are unavailable. Test purchases on a Play internal testing track before release.

## Platform differences and validation limits

SwiftUI, WidgetKit, Siri, StoreKit, and CloudKit cannot run on Android. This app uses native Android views, App Widgets, deep links, Google Play/RevenueCat, and Android notifications instead. Data is local with OS backup; there is no live sync between Android and iOS. Implement an authenticated shared sync service if cross-platform sync is required.

Theme colors, gradients/grids, case, custom typefaces, and checkbox styles are reused. Android's native dialogs and widgets have platform-specific layouts; widget text uses the launcher-compatible system font, and its background uses the theme's base color. This is not a pixel-identical SwiftUI port.

Before publishing, validate on a device: process restart persistence, permissions denied/granted, reminders after reboot, every widget size, recurring task completion, purchases/restores, TalkBack, large text, and edge-to-edge layout. Set your release signing configuration and supply Android-specific published privacy/terms pages. Current About links point to the repository's existing legal documents for review.
