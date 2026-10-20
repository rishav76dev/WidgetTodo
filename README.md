# Todo1

Todo1 is a native SwiftUI to-do app for iPhone (iOS 17+). Its main features are:

- **An interactive home-screen widget.** You can tick tasks off, and a "+" button opens quick add.
- **12 minimalist themes** that restyle both the widget and the app. Three are free. The rest unlock with Premium, which is a yearly subscription with a 1-week free trial or a one-time lifetime purchase.
- **iCloud sync** through the user's private CloudKit database. There are no accounts and no backend.
- **Siri, Shortcuts and Action button support** through "Add a task in Todo1".

"Todo1" is a working name. The public App Store name is chosen before submission (see [docs/appstore/metadata.md](docs/appstore/metadata.md)).

## Documents

| Document | For | What it covers |
|---|---|---|
| [docs/MAC_SETUP.md](docs/MAC_SETUP.md) | Whoever has the Mac | Building, running, testing and uploading the app step by step |
| [docs/LAUNCH_CHECKLIST.md](docs/LAUNCH_CHECKLIST.md) | App owner | Apple Developer, App Store Connect and RevenueCat setup; changing prices; the TestFlight test pass |
| [docs/appstore/metadata.md](docs/appstore/metadata.md) | App owner | App Store name, subtitle, description, keywords and review notes |
| [site/privacy.html](site/privacy.html), [site/terms.html](site/terms.html) | Public | Privacy Policy and Terms of Use, ready to host |
| [docs/superpowers/specs/](docs/superpowers/specs/) | Developers | Product and technical design |
| [docs/superpowers/plans/](docs/superpowers/plans/) | Developers | Implementation plan |

## Repository layout

```
project.yml                 XcodeGen spec. Generates Todo1.xcodeproj (the .xcodeproj is not committed)
Config/Base.xcconfig        Shared build settings; your own values go in Config/Local.xcconfig (git-ignored)
App/                        App target: app entry, views, services (notifications, purchases), resources
Widget/                     WidgetKit extension: widget, timeline provider, configuration intent
Shared/Intents/             App Intents compiled into both the app and the widget
Shared/Fonts/               Bundled SIL Open Font License fonts and their licence files
Packages/TodoCore/          Local Swift package, linked into both targets
  Sources/TodoKit/            Pure Foundation logic: repeat rules, grouping, themes, entitlements, deep links
  Sources/TodoData/           SwiftData models, container factory, repository (Apple platforms only)
  Sources/TodoUI/             Themed SwiftUI views shared by the app and the widget (Apple platforms only)
  Tests/TodoKitTests/         Unit tests for TodoKit (Swift Testing)
scripts/test-core.sh        Runs the TodoKit tests on Linux in Docker
scripts/parse-check.sh      Syntax-checks the Apple-only Swift files on Linux in Docker
site/                       Privacy Policy and Terms of Use pages
.github/workflows/ios.yml   macOS CI: generates the project, runs the package tests, builds for the simulator
```

## Running the tests

### On Linux (no Mac needed)

You need Docker. The scripts use the official `swift:6.1` image.

```bash
scripts/test-core.sh                         # all TodoKit unit tests
scripts/test-core.sh --filter RepeatRule     # one suite
scripts/parse-check.sh                       # syntax check of App/, Widget/, Shared/, TodoData, TodoUI
```

On Linux only `TodoKit` compiles and runs. SwiftUI, SwiftData, WidgetKit and RevenueCat code exists only on Apple platforms, so `parse-check.sh` can check its syntax but cannot type-check it.

### On a Mac

```bash
cd Packages/TodoCore && swift test
```

To build and run the app itself, follow [docs/MAC_SETUP.md](docs/MAC_SETUP.md).

### In GitHub Actions

If the repository is on GitHub, `.github/workflows/ios.yml` runs on a macOS runner every time you push. It runs the package tests and does a full unsigned simulator build. This is the only way to compile the app without a Mac. Open the **Actions** tab to see the results.
