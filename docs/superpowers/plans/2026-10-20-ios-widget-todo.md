# Todo1 (iOS widget to-do app) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native SwiftUI iPhone to-do app whose interactive home-screen widget and 12-theme catalogue (3 free, premium via RevenueCat yearly-with-trial or lifetime) are the core product, with iCloud sync and no backend.

**Architecture:**
- **Local Swift package `Packages/TodoCore` with three libraries:**
  - `TodoKit`: pure Foundation logic. It compiles and is tested on Linux through Docker.
  - `TodoData`: SwiftData models and the repository.
  - `TodoUI`: themed SwiftUI views shared by the app and the widget.

  Apple-only files are wrapped entirely in `#if canImport(SwiftData)` or `#if canImport(SwiftUI)`, so the whole package builds on Linux.
- **Two thin Xcode targets, `Todo1` (app) and `Todo1Widget` (WidgetKit extension),** generated from `project.yml` by XcodeGen. App Intents live in `Shared/Intents` and are compiled into both targets.

**Tech Stack:** Swift 5 language mode (swift-tools-version 5.10), SwiftUI, SwiftData + CloudKit, WidgetKit, App Intents, RevenueCat + RevenueCatUI (SPM `purchases-ios-spm`, 5.x), XcodeGen, Swift Testing, Docker `swift:6.1` for Linux tests.

**Spec:** `docs/superpowers/specs/2026-10-20-ios-widget-todo-design.md`

## Global Constraints

- iOS deployment target **17.0**. The package declares `.iOS(.v17), .macOS(.v14)` (macOS only so `swift build`/`swift test` work on a Mac host).
- `SWIFT_VERSION = 5.0` in Xcode targets and `swift-tools-version:5.10` in the package (Swift 5 language mode; avoids strict-concurrency build breaks).
- Identifiers:
  - Bundle IDs: `ai.shavastudios.todo1` and `ai.shavastudios.todo1.widget`
  - App Group: `group.ai.shavastudios.todo1`
  - iCloud container: `iCloud.ai.shavastudios.todo1`
  - URL scheme: `todo1`
  - Entitlement: `premium`
- Products:
  - `premium_yearly`: auto-renewable, 1 year, $4.99, intro offer of a free trial for 1 week, in subscription group "Premium"
  - `premium_lifetime`: non-consumable, $14.99
- Free themes default **3**; default theme id **`paper`**.
- **Schedule** at most **60** notifications and **delete** completed tasks after **30** days.
- Widget rows: small 1, medium 3, large 7, then "+N more".
- No ads, no tracking, no accounts, no backend, no React Native. Fonts are system fonts or SIL OFL only, each with its licence file. No SplenDO names, assets or copy, and no third-party trademarks in theme names.
- `TodoKit` imports **Foundation only** and must pass `scripts/test-core.sh` on Linux.
- Every Swift file outside `TodoKit` must pass `scripts/parse-check.sh`.
- Use `Calendar`/`Date` parameters instead of `Date()`/`.current` inside `TodoKit` logic, so tests are deterministic.

## Review Focus

1. **Completing an overdue repeating task** (daily task due 5 days ago): it should move to the first occurrence **after now** and keep its time of day, not to 4 days ago. Covered by Task 2: `overdueDailyJumpsPastNow`, `completingRepeatingTaskAdvancesAndStaysOpen`.
2. **Month-end and leap-day repeats** (monthly on Jan 31, yearly on Feb 29): these should clamp to Feb 28/29 and return to the 31st or 29th later without drifting. Covered by Task 2: `monthlyFrom31stDoesNotDrift`, `yearlyLeapDay`.
3. **Garbage remote config** (`free_theme_count` negative, as a string, or larger than the catalogue; `theme_order` with unknown ids): the app should use safe defaults and never lock every theme or crash. Covered by Task 6: `remoteMetadataGarbageFallsBack`, `freeCountClamped`.
4. **Corrupt or missing shared defaults, or a theme file missing a field:** the widget should render with defaults and Paper, not crash or show blank. Covered by Task 5: `missingFieldsUseDefaults`, `unknownEnumValuesUseDefaults`. Covered by Task 6: `corruptStoredDataReturnsDefaults`.
5. **Blank, whitespace-only or very long titles** from Quick Add or Siri: blanks should be rejected, and long titles trimmed and capped at 500 characters. Covered by Task 3: `blankTitleRejected`, `titleTrimmedAndCapped`.

---

## File Structure

```
project.yml                         XcodeGen spec (Task 13)
Config/Base.xcconfig                DEVELOPMENT_TEAM, REVENUECAT_API_KEY (Task 13)
scripts/test-core.sh                Docker swift test for TodoCore (Task 1)
scripts/parse-check.sh              Docker swiftc -parse over all Apple-side Swift (Task 1)
.github/workflows/ios.yml           macOS CI: xcodegen + swift test + xcodebuild (Task 13)
Packages/TodoCore/Package.swift     (Task 1)
Packages/TodoCore/Sources/TodoKit/
  AppConstants.swift                (Task 1)
  RepeatRule.swift                  (Task 2)
  TaskCompletion.swift              (Task 2)
  TaskSnapshot.swift                (Task 3)
  TaskTitle.swift                   (Task 3)
  TaskFilter.swift                  (Task 3)
  TaskGrouping.swift                (Task 3)
  DueDateFormatter.swift            (Task 3)
  DeepLink.swift                    (Task 4)
  CompletedTaskCleanup.swift        (Task 4)
  NotificationPlanner.swift         (Task 4)
  Theme/HexColor.swift, Theme/Theme.swift, Theme/ThemeCatalog.swift   (Task 5)
  Resources/Themes/index.json + 12 × <id>.json                         (Task 5)
  Entitlements/EntitlementState.swift, ThemeAccess.swift, SharedStore.swift (Task 6)
  Widget/WidgetLayout.swift, Widget/WidgetViewModel.swift, SampleTasks.swift (Task 7)
Packages/TodoCore/Sources/TodoData/  Models.swift, ModelContainerFactory.swift, TaskRepository.swift (Task 8)
Packages/TodoCore/Sources/TodoUI/    ThemeStyle.swift, ThemedBackground.swift, ThemedCheckbox.swift,
                                     ThemedTaskRow.swift, TaskListWidgetView.swift, FontRegistration.swift (Task 9)
Packages/TodoCore/Tests/TodoKitTests/  one test file per TodoKit source file
Shared/Intents/   ToggleTaskIntent.swift, AddTaskIntent.swift, ListEntity.swift,
                  WidgetFilterEntity.swift, ThemeEntity.swift, IntentSupport.swift  (Task 10)
Shared/Fonts/     IBMPlexMono-Regular.ttf, IBMPlexMono-Bold.ttf, PressStart2P-Regular.ttf,
                  Caveat-Variable.ttf, LICENSES/*.txt                            (Task 9)
Widget/           Todo1WidgetBundle.swift, TaskListWidget.swift, TaskListProvider.swift,
                  TaskListConfigurationIntent.swift, TargetRole.swift, Info.plist,
                  Todo1Widget.entitlements, PrivacyInfo.xcprivacy                  (Task 11)
App/              Todo1App.swift, AppModel.swift, TargetRole.swift, AppShortcuts.swift (Task 12)
App/Views/        RootView, HomeView, TaskRowView, QuickAddSheet, TaskEditorView, ListsView,
                  UndoBanner (Task 12); ThemeGalleryView, ThemePreviewView, OnboardingView,
                  SettingsView (Task 15)
App/Services/     NotificationScheduler.swift (Task 14), PurchaseManager.swift, PaywallSheet.swift (Task 15)
App/Resources/    Assets.xcassets (AppIcon, AccentColor), Info.plist, Todo1.entitlements,
                  PrivacyInfo.xcprivacy, Todo1.storekit                            (Task 13)
site/             privacy.html, terms.html                                         (Task 16)
docs/MAC_SETUP.md, docs/LAUNCH_CHECKLIST.md, docs/appstore/metadata.md            (Task 16)
```

Test command (all TodoKit tasks): `SWIFT_SCRATCH=.build-linux-<task> scripts/test-core.sh --filter <SuiteName>`. Expected pass output: `Test run with N tests passed`.

---

### Task 1: Package skeleton and tooling

**Files:**
- Create: `Packages/TodoCore/Package.swift`
- Create: `Packages/TodoCore/Sources/TodoKit/AppConstants.swift`
- Create: `scripts/test-core.sh`, `scripts/parse-check.sh`
- Create: `Packages/TodoCore/Tests/TodoKitTests/AppConstantsTests.swift`
- Create: placeholder `Sources/TodoData/TodoData.swift` and `Sources/TodoUI/TodoUI.swift`, each containing only `#if canImport(SwiftData)` / `#if canImport(SwiftUI)` and `#endif`
- Modify: `.gitignore` (add `.build-linux*`, `*.xcodeproj`, `Config/Local.xcconfig`)

**Interfaces:**
- Produces:
  - `Package.swift`: products `TodoKit`, `TodoData` (depends on TodoKit), `TodoUI` (depends on TodoKit). `TodoKit` has `resources: [.process("Resources")]`. Test target `TodoKitTests` uses Swift Testing (`import Testing`).
  - `public enum AppConstants` with `appGroupID`, `iCloudContainerID`, `urlScheme`, `entitlementID`, `defaultThemeID`, `defaultFreeThemeCount = 3`, `maxScheduledNotifications = 60`, `completedRetentionDays = 30`, `maxTitleLength = 500`, `privacyPolicyURL = URL(string: "https://shavastudios.ai/todo1/privacy")!`, `termsURL = URL(string: "https://shavastudios.ai/todo1/terms")!`. Values come from Global Constraints.
- `scripts/test-core.sh`: runs `docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v <repo>/Packages/TodoCore:/pkg -w /pkg swift:6.1 swift test --scratch-path "/pkg/${SWIFT_SCRATCH:-.build-linux}" "$@"`.
- `scripts/parse-check.sh`: runs `swiftc -parse` in the same image over every `*.swift` under `App Widget Shared Packages/TodoCore/Sources/TodoData Packages/TodoCore/Sources/TodoUI`. It prints each failing file and exits non-zero on any failure, and exits 0 when no files exist yet.

- [ ] **Step 1:** Write `AppConstantsTests.swift`, `@Suite struct AppConstantsTests`. Test `identifiersMatchSpec` asserts `AppConstants.appGroupID == "group.ai.shavastudios.todo1"`, `AppConstants.defaultFreeThemeCount == 3`, `AppConstants.maxScheduledNotifications == 60`.
- [ ] **Step 2:** Run `scripts/test-core.sh --filter AppConstantsTests`. Expected: build FAIL, `AppConstants` not found.
- [ ] **Step 3:** Create `Package.swift`, `AppConstants.swift`, the placeholders, an empty `Sources/TodoKit/Resources/Themes/index.json` containing `[]`, and both scripts (`chmod +x`).
- [ ] **Step 4:** Run `scripts/test-core.sh --filter AppConstantsTests`. Expected: PASS. Run `scripts/parse-check.sh`. Expected: exit 0.
- [ ] **Step 5:** Commit `chore: TodoCore package skeleton and Linux test tooling`.

### Task 2: Repeat rules and completion

**Files:** Create `Sources/TodoKit/RepeatRule.swift`, `Sources/TodoKit/TaskCompletion.swift`; Test `Tests/TodoKitTests/RepeatRuleTests.swift`, `TaskCompletionTests.swift`

**Interfaces:**
- Produces: `public enum RepeatRule: String, CaseIterable, Codable, Sendable { case none, daily, weekdays, weekly, monthly, yearly }`
  - `init(rawOrNone: String)`: unknown raw value gives `.none`
  - `var displayName: String`: "Never", "Daily", "Weekdays", "Weekly", "Monthly", "Yearly"
  - `func nextOccurrence(after due: Date, now: Date, calendar: Calendar) -> Date?`: returns nil for `.none`
- Produces: `public struct CompletionResult: Equatable, Sendable { isCompleted: Bool; completedAt: Date?; dueDate: Date? }` and `public enum TaskCompletion { static func toggle(isCompleted: Bool, dueDate: Date?, repeatRule: RepeatRule, now: Date, calendar: Calendar) -> CompletionResult }`

**Algorithm (`nextOccurrence`):**
- For `k = 1, 2, …` let `candidate = calendar.date(byAdding: unit, value: k * step, to: due)`.
  - daily: `.day`, 1
  - weekly: `.day`, 7
  - monthly: `.month`, 1
  - yearly: `.year`, 1
  - weekdays: `.day`, 1, skipping candidates where `calendar.isDateInWeekend`
- Return the first candidate `> now`.
- Always offsetting from the original `due` (not chaining) prevents month-end drift.
- Cap the loop at 10,000 iterations and return nil if it is exceeded.

**Toggle rules:**
- Open, repeating and has a due date gives `(false, nil, nextOccurrence)`.
- Otherwise open gives `(true, now, dueDate)`.
- Completed gives `(false, nil, dueDate)`.

Tests use `Calendar(identifier: .gregorian)` with `timeZone = TimeZone(identifier: "America/New_York")!`.

- [ ] **Step 1:** Write the failing tests:
  - `dailyNext`: due 2026-03-10 09:00, now 2026-03-10 08:00, gives 2026-03-11 09:00.
  - `overdueDailyJumpsPastNow`: due 2026-03-05 09:00, now 2026-03-10 10:00, gives 2026-03-11 09:00.
  - `weekdaysSkipsWeekend`: due Fri 2026-03-13 09:00, now the same instant, gives Mon 2026-03-16 09:00.
  - `monthlyFrom31stDoesNotDrift`: due 2026-01-31, now 2026-01-31 gives 2026-02-28; now 2026-03-01 gives 2026-03-31.
  - `yearlyLeapDay`: due 2028-02-29, now 2028-03-01 gives 2029-02-28.
  - `dailyAcrossDSTKeepsWallClock`: due 2026-03-07 09:00 NY, now the same, gives 2026-03-08 with hour component 9.
  - `noneReturnsNil`.
  - `unknownRawIsNone`: `RepeatRule(rawOrNone: "fortnightly") == .none`.
  - `completingRepeatingTaskAdvancesAndStaysOpen`: daily, due 5 days ago, gives `isCompleted == false`, `completedAt == nil` and `dueDate > now`.
  - `completingPlainTaskSetsCompletedAt`.
  - `uncompletingClearsCompletedAt`.
  - `repeatingWithoutDueDateJustCompletes`.
- [ ] **Step 2:** Run `scripts/test-core.sh --filter "RepeatRuleTests|TaskCompletionTests"`. Expected: FAIL to compile.
- [ ] **Step 3:** Implement both files per the interfaces and algorithm above.
- [ ] **Step 4:** Rerun. Expected: PASS.
- [ ] **Step 5:** Commit `feat(core): repeat rules and completion toggling`.

### Task 3: Task snapshot, titles, filters, grouping and due labels

**Files:** Create `TaskSnapshot.swift`, `TaskTitle.swift`, `TaskFilter.swift`, `TaskGrouping.swift`, `DueDateFormatter.swift`; Test `TaskTitleTests.swift`, `TaskFilterTests.swift`, `TaskGroupingTests.swift`, `DueDateFormatterTests.swift`

**Interfaces:**
- Consumes: `RepeatRule` (Task 2).
- Produces:
  - `public struct TaskSnapshot: Identifiable, Hashable, Codable, Sendable`
    - Stored properties: `id: UUID, title: String, notes: String, dueDate: Date?, hasDueTime: Bool, repeatRule: RepeatRule, isCompleted: Bool, completedAt: Date?, listID: UUID?, listName: String, sortIndex: Int, createdAt: Date`
    - A memberwise `public init` with defaults `notes: ""`, `hasDueTime: false`, `repeatRule: .none`, `isCompleted: false`, `completedAt: nil`, `listID: nil`, `listName: ""`, `sortIndex: 0`.
  - `public enum TaskTitle { static func normalized(_ raw: String, maxLength: Int = AppConstants.maxTitleLength) -> String? }`
    - Trims whitespace and newlines and replaces internal newlines with spaces.
    - Returns nil if empty; otherwise truncates to `maxLength` characters.
  - `public enum TaskFilter: Hashable, Codable, Sendable { case all, today, list(UUID) }`
    - `func includes(_ t: TaskSnapshot, now: Date, calendar: Calendar) -> Bool`: `today` means overdue or due today; `list` matches `listID`.
    - `var rawValue: String` gives `"all"`, `"today"` or the UUID string.
    - `init?(rawValue: String)`.
  - `public enum TaskGroup: String, CaseIterable, Sendable { case overdue, today, tomorrow, upcoming, noDate, completed }` with `var title: String`: "Overdue", "Today", "Tomorrow", "Upcoming", "No date", "Completed".
  - `public struct GroupedTasks: Equatable, Sendable { group: TaskGroup; tasks: [TaskSnapshot] }`.
  - `public enum TaskGrouping`:
    - `static func isOverdue(_:now:calendar:) -> Bool`: an open task with a due date where, for timed tasks, `dueDate < now`; for all-day tasks, the start of the due day is before the start of today.
    - `static func group(of:now:calendar:) -> TaskGroup`.
    - `static func grouped(_:now:calendar:) -> [GroupedTasks]`: only non-empty groups, in `TaskGroup` case order.
    - `static func sortedOpen(_:now:calendar:) -> [TaskSnapshot]`.
    - Sort open tasks by dueDate ascending (nil last), then `sortIndex`, then `createdAt`. Sort completed tasks by `completedAt` descending.
  - `public enum DueDateFormatter { static func label(for: TaskSnapshot, now: Date, calendar: Calendar, locale: Locale) -> String? }`
    - Returns nil without a due date.
    - Day word: "Today" / "Tomorrow" / "Yesterday", otherwise a `setLocalizedDateFormatFromTemplate("EEEdMMM")` date.
    - Timed tasks append ", " and the template `"jmm"` time.

- [ ] **Step 1:** Write the failing tests:
  - `blankTitleRejected`: `"   \n "` gives nil.
  - `titleTrimmedAndCapped`: `"  a\nb  "` gives `"a b"`, and a 600× `"x"` string gives a count of 500.
  - `todayFilterIncludesOverdueAndToday`.
  - `listFilterMatchesListID`.
  - `filterRawValueRoundTrips` for all three cases; `TaskFilter(rawValue: "bogus") == nil`.
  - `timedTaskOverdueAfterDueInstant`.
  - `allDayTaskNotOverdueOnItsDay`.
  - `groupingOrderAndEmptyGroupsOmitted`: tasks in overdue, tomorrow and noDate give exactly those 3 groups in that order.
  - `completedSortedNewestFirst`.
  - `sortedOpenPutsNilDueLast`.
  - `labelTodayWithTime` has prefix `"Today, "`.
  - `labelTomorrowAllDay == "Tomorrow"`.
  - `labelNilWithoutDueDate`.
  - Use locale `en_US` and the New York calendar.
- [ ] **Step 2:** Run with `--filter "TaskTitleTests|TaskFilterTests|TaskGroupingTests|DueDateFormatterTests"`. Expected: FAIL.
- [ ] **Step 3:** Implement the five files.
- [ ] **Step 4:** Rerun. Expected: PASS.
- [ ] **Step 5:** Commit `feat(core): task snapshot, filters, grouping, due labels`.

### Task 4: Deep links, cleanup, notification planning

**Files:** Create `DeepLink.swift`, `CompletedTaskCleanup.swift`, `NotificationPlanner.swift`; Test `DeepLinkTests.swift`, `CompletedTaskCleanupTests.swift`, `NotificationPlannerTests.swift`

**Interfaces:**
- Consumes: `TaskSnapshot`, `TaskFilter` (Task 3).
- Produces:
  - `public enum DeepLink: Equatable, Sendable { case quickAdd(TaskFilter?), task(UUID), themes }`
    - `init?(url: URL)`: the scheme must equal `AppConstants.urlScheme`. Hosts are `quick-add` (optional `list` query item parsed via `TaskFilter(rawValue:)`; invalid gives `.quickAdd(nil)`), `task` (path component is a UUID, otherwise nil) and `themes`.
    - `var url: URL`.
  - `public enum CompletedTaskCleanup { static func idsToDelete(_ tasks: [TaskSnapshot], now: Date, retentionDays: Int = AppConstants.completedRetentionDays, calendar: Calendar) -> [UUID] }`: completed tasks whose `completedAt <= now - retentionDays days`. A completed task with nil `completedAt` is never deleted.
  - `public struct PlannedNotification: Equatable, Sendable { taskID: UUID; fireDate: Date; title: String; body: String; var identifier: String { "task-\(taskID.uuidString)" } }`.
  - `public enum NotificationPlanner { static let identifierPrefix = "task-"; static func plan(_ tasks: [TaskSnapshot], now: Date, limit: Int = AppConstants.maxScheduledNotifications) -> [PlannedNotification] }`: open tasks with `hasDueTime` and `dueDate > now`, ascending by `fireDate`, first `limit`. `title` = task title; `body` = `listName`, or "Reminder" when that is empty.

- [ ] **Step 1:** Write the failing tests:
  - `quickAddRoundTrip`: `.quickAdd(.today)`, `.quickAdd(.list(id))` and `.quickAdd(nil)` each give `DeepLink(url: x.url) == x`.
  - `taskRoundTrip`, `themesRoundTrip`.
  - `wrongSchemeRejected` (`https://quick-add`).
  - `badTaskIDRejected` (`todo1://task/nope`).
  - `invalidListParamGivesNilFilter`.
  - `deletesOnlyOlderThan30Days`: completed 31 days ago is deleted; 29 days ago is kept; open tasks are kept.
  - `nilCompletedAtKept`.
  - `plansOnlyFutureTimedOpenTasks`.
  - `respectsLimitSoonestFirst`: 100 tasks with limit 60 give 60, sorted, with the first equal to the soonest.
  - `emptyListNameBodyIsReminder`.
- [ ] **Step 2:** Run with `--filter "DeepLinkTests|CompletedTaskCleanupTests|NotificationPlannerTests"`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Rerun. Expected: PASS.
- [ ] **Step 5:** Commit `feat(core): deep links, cleanup policy, notification planner`.

### Task 5: Theme model, decoding and the 12-theme catalogue

**Files:** Create `Theme/HexColor.swift`, `Theme/Theme.swift`, `Theme/ThemeCatalog.swift`, `Resources/Themes/index.json` (replacing `[]`), and 12 theme files (`paper`, `midnight`, `mono-mint`, `terminal`, `brutalist`, `receipt`, `swiss`, `blueprint`, `pocket-8bit`, `neon`, `zen`, `sticky-note`); Test `HexColorTests.swift`, `ThemeDecodingTests.swift`, `ThemeCatalogTests.swift`

**Interfaces:**
- Produces:
  - `public struct HexColor: Codable, Hashable, Sendable`
    - `red, green, blue, alpha: Double` (0…1).
    - `init?(_ hex: String)` accepts `#RGB`, `#RRGGBB`, `#RRGGBBAA`, case-insensitive.
    - Decodes from a string. An invalid string throws `DecodingError` (the `Theme` decoder catches this and substitutes the default).
    - `var hexString: String`.
  - `public struct Theme: Codable, Identifiable, Hashable, Sendable`:

| Field | Type | Default |
|---|---|---|
| `id` | String | `"paper"` |
| `name` | String | `"Paper"` |
| `colorScheme` | `ThemeColorScheme` (`light`/`dark`) | `light` |
| `background` | `ThemeBackground { type: BackgroundType (solid/gradient/grid); colors: [HexColor]; gridColor: HexColor? }` | solid `#FFFFFF` |
| `textPrimary` / `textSecondary` / `accent` / `overdue` | HexColor | `#111111` / `#6B6B6B` / `#111111` / `#D93025` |
| `font` | `FontSpec { family: FontFamily (system/serif/mono/rounded/custom); customName: String?; weight: FontWeightSpec (light/regular/medium/semibold/bold/heavy/black); scale: Double; textCase: TextCaseSpec (none/upper/lower), JSON key "case" }` | system, nil, regular, 1.0, none |
| `header` | `HeaderSpec { style: HeaderStyle (plain/bold/prompt/stamp); prefix: String }` | plain, "" |
| `row` | `RowSpec { style: RowStyle (plain/divider/card/dashed); spacing: Double }` | plain, 6 |
| `checkbox` | `CheckboxStyle` (circle/square/bracket/strike/dot) | circle |
| `footer` | `FooterStyle` (none/count/receipt) | none |
| `layout` | `LayoutStyle` (list/focus) | list |
| `glow` | Bool | false |
| `cornerRadius` / `padding` | Double | 16 / 14 |

  - `Theme` behaviour:
    - Every field decodes with `decodeIfPresent` and falls back to its default.
    - Every enum decodes through a helper that maps unknown raw strings to that enum's default.
    - Invalid colours fall back to the field default.
    - `public static let fallback: Theme` is Paper, defined in Swift (not loaded from JSON).
  - `public struct ThemeCatalog: Sendable`
    - `let themes: [Theme]`, `init(themes:)`.
    - `static func load(bundle: Bundle) -> ThemeCatalog`: reads `index.json` (an array of ids), then each `<id>.json`. Skips unreadable files and guarantees `fallback` is present at index 0 if `paper` is missing.
    - `static let bundled = load(bundle: .module)`.
    - `func theme(id: String?) -> Theme`: unknown or nil gives the `paper` theme, else `.fallback`.
    - `func ordered(by order: [String]) -> [Theme]`: ids from `order` that exist come first, then the rest in bundled order, with no duplicates.
- **Catalogue content:** follow spec section 8.
  - **Order:** `index.json` lists `paper, midnight, mono-mint` first, then the rest in spec order.
  - **Fonts:**
    - `terminal`, `receipt`, `blueprint`: `custom` with `customName: "IBMPlexMono-Regular"`
    - `pocket-8bit`: `"PressStart2P-Regular"`
    - `sticky-note`: `"Caveat-Regular"`
    - `paper`, `zen`: `serif`
    - `mono-mint`: `mono`
    - `neon`: `rounded`
    - `brutalist`: `system` with `black` weight and `upper` case
    - `swiss`: `system` with `bold` weight and `custom`-free
  - **Per-theme settings:**
    - `receipt` uses footer `receipt` and row `dashed`.
    - `blueprint` uses background `grid`.
    - `zen` uses layout `focus` and footer `count`.
    - `neon` uses `glow: true` with colorScheme `dark`.
    - `terminal` uses checkbox `bracket`, header `prompt` with prefix `"> "`, and case `lower`.

- [ ] **Step 1:** Write the failing tests:
  - `parsesSixAndEightDigit`, `parsesThreeDigit`, `rejectsGarbage` (`"#GG0000"` and `"red"` give nil).
  - `missingFieldsUseDefaults`: decoding `{"id":"x","name":"X"}` gives `checkbox == .circle`, `padding == 14`, `background.type == .solid`.
  - `unknownEnumValuesUseDefaults`: `{"id":"x","checkbox":"hexagon","row":{"style":"zigzag"}}` gives `.circle` and `.plain`.
  - `invalidColorUsesDefault`.
  - `bundledCatalogHas12UniqueThemesPaperFirst`: count 12, unique ids, first `paper`, and every theme's `id` equals its filename.
  - `unknownIdReturnsPaper`.
  - `orderedByRemoteOrder`: `["neon","bogus","paper"]` gives first two ids `neon, paper`, total count 12.
  - `emptyBundleStillHasFallback`: `ThemeCatalog.load(bundle: Bundle(for:...))` or `ThemeCatalog(themes: [])` followed by `theme(id: "x").id == "paper"`.
- [ ] **Step 2:** Run with `--filter "HexColorTests|ThemeDecodingTests|ThemeCatalogTests"`. Expected: FAIL.
- [ ] **Step 3:** Implement the three source files and write the 13 JSON files.
- [ ] **Step 4:** Rerun. Expected: PASS.
- [ ] **Step 5:** Commit `feat(core): theme model, defaulting decoder, 12-theme catalogue`.

### Task 6: Entitlements, theme access, shared store

**Files:** Create `Entitlements/EntitlementState.swift`, `Entitlements/ThemeAccess.swift`, `Entitlements/SharedStore.swift`; Test `EntitlementStateTests.swift`, `ThemeAccessTests.swift`, `SharedStoreTests.swift`

**Interfaces:**
- Consumes: `Theme`, `ThemeCatalog` (Task 5).
- Produces:
  - `public struct EntitlementState: Codable, Equatable, Sendable`
    - Fields: `isPremium: Bool; freeThemeCount: Int; themeOrder: [String]`.
    - `static let default = EntitlementState(isPremium: false, freeThemeCount: AppConstants.defaultFreeThemeCount, themeOrder: [])`.
    - `static func from(isPremium: Bool, offeringMetadata: [String: Any]) -> EntitlementState`:
      - Reads `free_theme_count`, accepting `Int` or a `Double` with an integral value; anything else gives the default.
      - Reads `theme_order` as `[String]`; anything else gives `[]`.
  - `public enum ThemeAccess`:
    - `static func freeThemeIDs(catalog:state:) -> [String]`: the first `clamp(freeThemeCount, 0...catalog.count)` themes of `catalog.ordered(by: state.themeOrder)`. If the clamped count is 0, the first theme is still free, so the app always has one usable theme.
    - `static func isUnlocked(themeID:catalog:state:) -> Bool`: premium gives true.
    - `static func effectiveTheme(selectedID: String?, catalog:, state:) -> (theme: Theme, isLockedFallback: Bool)`: nil gives the first free theme with `false`; a locked theme gives the first free theme with `true`.
  - `public protocol KeyValueStore: AnyObject { func readData(forKey: String) -> Data?; func writeData(_ data: Data?, forKey: String) }`, with conformances `extension UserDefaults: KeyValueStore` and `public final class InMemoryKeyValueStore: KeyValueStore`.
  - `public struct AppPreferences: Codable, Equatable, Sendable`
    - Fields: `appThemeID: String = AppConstants.defaultThemeID; hasCompletedOnboarding = false; notificationsEnabled = true; hasAskedNotificationPermission = false`.
    - A tolerant decoder: missing keys use defaults.
  - `public final class SharedStore: @unchecked Sendable`
    - `init(store: KeyValueStore)`.
    - `static func appGroup() -> SharedStore`: `UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard`.
    - `loadEntitlements() -> EntitlementState`, `saveEntitlements(_:)`, `loadPreferences() -> AppPreferences`, `savePreferences(_:)`.
    - JSON stored under the keys `"entitlements.v1"` and `"preferences.v1"`. Corrupt or missing data gives the defaults.

- [ ] **Step 1:** Write the failing tests:
  - `remoteMetadataParsed`: `["free_theme_count": 4, "theme_order": ["neon"]]` gives 4 and `["neon"]`.
  - `remoteMetadataGarbageFallsBack`: `["free_theme_count": "lots", "theme_order": 7]` gives 3 and `[]`. A `3.0` Double gives 3.
  - `freeCountClamped`: -5 gives 1 free theme; 99 gives 12.
  - `premiumUnlocksAll`.
  - `firstThreeFreeByDefault`: `paper`, `midnight`, `mono-mint` unlocked; `terminal` locked.
  - `remoteOrderChangesWhichAreFree`.
  - `lockedSelectionFallsBackWithFlag`: selecting `neon` while not premium gives `paper` and `true`.
  - `nilSelectionNoFlag`.
  - `roundTripsEntitlementsAndPreferences`.
  - `corruptStoredDataReturnsDefaults`: write `Data("{oops".utf8)` under both keys; loading returns the defaults.
- [ ] **Step 2:** Run with `--filter "EntitlementStateTests|ThemeAccessTests|SharedStoreTests"`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Rerun. Expected: PASS.
- [ ] **Step 5:** Commit `feat(core): entitlement state, theme gating, shared store`.

### Task 7: Widget layout and view model

**Files:** Create `Widget/WidgetLayout.swift`, `Widget/WidgetViewModel.swift`, `SampleTasks.swift`; Test `WidgetLayoutTests.swift`

**Interfaces:**
- Consumes: `TaskSnapshot`, `TaskFilter`, `TaskGrouping` (Task 3).
- Produces:
  - `public enum WidgetSize: String, Sendable { case small, medium, large; var maxRows: Int }`: 1, 3 and 7.
  - `public struct WidgetContent: Equatable, Sendable { visible: [TaskSnapshot]; hiddenCount: Int; openCount: Int }`.
  - `public enum WidgetLayout`:
    - `static func content(tasks:filter:size:now:calendar:) -> WidgetContent`: filter, then open tasks only, then `sortedOpen`, then the prefix.
    - `static func nextRefreshDate(tasks:now:calendar:) -> Date`: the minimum of the next midnight, the earliest open timed `dueDate > now`, and `now + 3600`.
  - `public struct WidgetViewModel: Equatable, Sendable`
    - Fields: `title: String; filter: TaskFilter; content: WidgetContent; isLockedFallback: Bool; now: Date`.
    - `static func title(for filter: TaskFilter, listName: String?) -> String`: "All Tasks" / "Today" / the list name, or "Tasks" when nil.
  - `public enum SampleTasks { static func make(now: Date, calendar: Calendar) -> [TaskSnapshot] }`: 6 English sample tasks for previews. One is overdue, two are today (one timed), one tomorrow, one upcoming and one with no date, all in a "Personal" list.

- [ ] **Step 1:** Write the failing tests:
  - `mediumShowsThreeAndCountsHidden`: 5 open and 1 completed gives 3 visible, `hiddenCount == 2`, `openCount == 5`.
  - `smallShowsOne`.
  - `filterApplied`.
  - `refreshAtNextDueTime`: due in 20 minutes gives now + 20 min.
  - `refreshCappedAtOneHour`.
  - `refreshAtMidnightWhenSooner`: now 23:30, nothing due, gives 00:00.
  - `sampleTasksCoverAllGroupsExceptCompleted`.
- [ ] **Step 2:** Run with `--filter WidgetLayoutTests`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Rerun. Expected: PASS.
- [ ] **Step 5:** Commit `feat(core): widget layout, refresh policy, sample data`.

### Task 8: SwiftData models, container factory and repository (Apple-only)

**Files:** Replace `Sources/TodoData/TodoData.swift` with `Models.swift`, `ModelContainerFactory.swift` and `TaskRepository.swift`, each wrapped entirely in `#if canImport(SwiftData)`.

**Interfaces:**
- Consumes: `RepeatRule`, `TaskCompletion`, `TaskSnapshot`, `TaskTitle`, `CompletedTaskCleanup`, `AppConstants`.
- Produces:
  - `@Model public final class TaskList` and `@Model public final class TaskItem`, exactly as in spec section 5. Every property is public. They add `public init(...)`, `TaskItem.repeatRule: RepeatRule` (a computed property over `repeatRuleRaw`) and `TaskItem.snapshot: TaskSnapshot`.
  - `public enum ModelContainerFactory`
    - `public enum Role { case app, widget }`.
    - `public static func make(role: Role, inMemory: Bool = false) throws -> ModelContainer`.
    - The store URL is `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)/Todo1.store`, or Application Support if that is nil.
    - The configuration is `ModelConfiguration(schema:url:cloudKitDatabase:)` with `.private(AppConstants.iCloudContainerID)` for `.app` and `.none` for `.widget`.
    - `public static func shared(role: Role) throws -> ModelContainer` caches one container per process.
  - `@MainActor public final class TaskRepository`:
    - `init(context: ModelContext)`.
    - Lists:
      - `lists() throws -> [TaskList]`: sorted by `sortIndex`.
      - `ensureDefaultList(name: String = "Personal") throws -> TaskList`.
      - `addList(name: String) throws -> TaskList`: uses `TaskTitle.normalized`; a blank name throws `.emptyTitle`.
      - `renameList(id: UUID, name: String) throws`.
      - `deleteList(id: UUID) throws`.
      - `reorderLists(_ ids: [UUID]) throws`.
    - Tasks:
      - `snapshots() throws -> [TaskSnapshot]`.
      - `task(id: UUID) throws -> TaskItem?`.
      - `addTask(title:notes:dueDate:hasDueTime:repeatRule:listID:) throws -> TaskItem`, with `notes` defaulting to `""`:
        - A blank title throws `RepositoryError.emptyTitle`.
        - A nil or unknown `listID` uses `ensureDefaultList()`.
      - `updateTask(id:title:notes:dueDate:hasDueTime:repeatRule:listID:) throws`.
      - `toggleCompletion(id: UUID, now: Date = .now, calendar: Calendar = .current) throws`: applies `TaskCompletion.toggle`.
      - `deleteTask(id: UUID) throws`.
      - `restore(_ snapshot: TaskSnapshot) throws`: for undo.
      - `purgeCompleted(now: Date = .now, calendar: Calendar = .current) throws -> Int`.
    - Every mutating method calls `context.save()`.
  - `public enum RepositoryError: Error { case emptyTitle, notFound }`.
- CloudKit rules: every attribute has a default or is optional, relationships are optional, and there is no `.unique`.

- [ ] **Step 1:** Implement the three files.
- [ ] **Step 2:** Run `scripts/parse-check.sh`. Expected: exit 0. Run `scripts/test-core.sh`. Expected: all previous tests PASS, which proves the guarded files compile away on Linux.
- [ ] **Step 3:** Commit `feat(data): SwiftData models, shared container, repository`.

### Task 9: Themed SwiftUI components and fonts (Apple-only)

**Files:** Replace `Sources/TodoUI/TodoUI.swift` with `ThemeStyle.swift`, `ThemedBackground.swift`, `ThemedCheckbox.swift`, `ThemedTaskRow.swift`, `TaskListWidgetView.swift` and `FontRegistration.swift`, all wrapped in `#if canImport(SwiftUI)`. Also add `Shared/Fonts/*.ttf` and `Shared/Fonts/LICENSES/<Family>-OFL.txt`, downloaded from `https://github.com/google/fonts/raw/main/ofl/{ibmplexmono,pressstart2p,caveat}/`.

**Interfaces:**
- Consumes: `Theme` and its specs, `HexColor`, `TaskSnapshot`, `WidgetViewModel`, `WidgetSize`, `TaskGrouping.isOverdue`, `DueDateFormatter.label`.
- Produces:
  - `extension HexColor { public var color: Color }`.
  - `public struct ThemeStyle`:
    - `init(_ theme: Theme)`.
    - `func font(_ role: FontRole) -> Font`, where `public enum FontRole { case header, title, caption, display }` maps to base sizes 15 / 14 / 11 / 28, multiplied by `font.scale`. Custom fonts use `Font.custom(customName, size:)`, and system families map to `.serif`, `.monospaced` and `.rounded` designs.
    - `func cased(_ s: String) -> String`.
  - `public struct ThemedBackground: View { init(theme: Theme) }`: solid, a linear gradient, or a grid drawn with `Canvas` in `gridColor`.
  - `public struct ThemedCheckbox: View { init(theme: Theme, isCompleted: Bool) }`, by style:
    - circle: `circle` / `checkmark.circle.fill`
    - square: `square` / `checkmark.square.fill`
    - bracket: text `[ ]` / `[x]`
    - strike: a dash
    - dot: a small filled or empty dot
  - `public struct ThemedTaskRow: View { init(task: TaskSnapshot, theme: Theme, now: Date, checkbox: AnyView) }`: title (cased), the due label in `textSecondary`, or `overdue` when overdue. Completed tasks are struck through.
  - `public struct TaskListWidgetView: View`
    - `init(model: WidgetViewModel, theme: Theme, size: WidgetSize, checkbox: @escaping (TaskSnapshot) -> AnyView, addLink: URL, taskLink: @escaping (TaskSnapshot) -> URL?)`.
    - Layout:
      - The header shows the title (with the prefix or stamp per `header.style`) and a "+" `Link(destination: addLink)`.
      - Rows go up to `size.maxRows`, or 1 when `theme.layout == .focus`, each wrapped in a `Link` when `taskLink` returns non-nil.
      - "+N more" appears when `hiddenCount > 0`.
      - Footer: `.count` shows "N tasks"; `.receipt` shows a dashed rule and "TOTAL: N ITEMS".
      - The empty state shows "All clear".
      - When `isLockedFallback`, a caption reads "Theme locked · tap to unlock".
    - Rendering modes: reads `@Environment(\.widgetRenderingMode)`. In non-`fullColor` modes it applies `.widgetAccentable()` to the header and checkboxes and drops the glow. The view does **not** draw the background; callers use `containerBackground` or `ThemedBackground`.
  - `public enum FontRegistration { static func registerBundledFonts() }`: an idempotent no-op if `UIAppFonts` already loaded the fonts. It uses `CTFontManagerRegisterFontsForURL` for `.ttf` files in `Bundle.main`.

- [ ] **Step 1:** Download the fonts and licences. Verify each `.ttf` begins with bytes `00 01 00 00` (`xxd -l4`).
- [ ] **Step 2:** Implement the six files, plus a `#Preview` in `TaskListWidgetView.swift` that shows `SampleTasks` in `terminal` at medium size.
- [ ] **Step 3:** Run `scripts/parse-check.sh` and `scripts/test-core.sh`. Expected: exit 0 / PASS.
- [ ] **Step 4:** Commit `feat(ui): themed components, shared widget view, OFL fonts`.

### Task 10: App Intents shared by app and widget

**Files:** Create in `Shared/Intents/`: `IntentSupport.swift`, `ToggleTaskIntent.swift`, `AddTaskIntent.swift`, `ListEntity.swift`, `WidgetFilterEntity.swift`, `ThemeEntity.swift`

**Interfaces:**
- Consumes: `TaskRepository`, `ModelContainerFactory.shared(role:)`, `ThemeCatalog.bundled`, `ThemeAccess`, `SharedStore`, `TaskFilter`, `TaskTitle`.
- Consumes: `TargetRole.role: ModelContainerFactory.Role`. Each target defines `enum TargetRole { static let role: ModelContainerFactory.Role }` (Tasks 11 and 12).
- Produces:
  - `enum IntentSupport { @MainActor static func repository() throws -> TaskRepository; static func reloadWidgets() }`: `WidgetCenter.shared.reloadAllTimelines()`.
  - `struct ToggleTaskIntent: AppIntent`:
    - `static var title: LocalizedStringResource = "Toggle Task"`, `static var isDiscoverable = false`.
    - `@Parameter(title: "Task ID") var taskID: String`, with `init()` and `init(taskID: String)`.
    - `@MainActor func perform() async throws -> some IntentResult` toggles the task and reloads the widgets.
  - `struct AddTaskIntent: AppIntent`:
    - `title "Add Task"`, `openAppWhenRun = false`.
    - `@Parameter(title: "Task", requestValueDialog: "What do you need to do?") var taskTitle: String`.
    - `@Parameter(title: "List") var list: ListEntity?`.
    - `perform` normalises the title (blank throws `$taskTitle.needsValueError("What do you need to do?")`), adds the task, reloads the widgets, and returns `.result(dialog: "Added “\(title)”")`.
  - `struct ListEntity: AppEntity`: `id: UUID`, `name: String`, with a `ListEntityQuery: EntityQuery` that returns repository lists.
  - `struct WidgetFilterEntity: AppEntity`: `id: String` (a `TaskFilter.rawValue`), `name`, `var filter: TaskFilter`.
    - Its query's `suggestedEntities` are All, Today, then every list.
    - `defaultResult()` is All.
  - `struct ThemeEntity: AppEntity`: `id: String`, `name: String`, `isLocked: Bool`. The display title is `name` plus ` 🔒` when locked.
    - The query lists `ThemeCatalog.bundled.ordered(by:)` using `SharedStore.appGroup().loadEntitlements()`.
    - `defaultResult()` returns the theme for `loadPreferences().appThemeID`.

- [ ] **Step 1:** Implement.
- [ ] **Step 2:** Run `scripts/parse-check.sh`. Expected: exit 0.
- [ ] **Step 3:** Commit `feat(intents): toggle, add-task, list/filter/theme entities`.

### Task 11: Widget extension

**Files:** Create in `Widget/`: `Todo1WidgetBundle.swift` (`@main`), `TaskListWidget.swift`, `TaskListProvider.swift`, `TaskListConfigurationIntent.swift`, `TargetRole.swift` (`.widget`), `Info.plist`, `Todo1Widget.entitlements` (App Group only), `PrivacyInfo.xcprivacy` (UserDefaults reason `1C8F.1`, no tracking)

**Interfaces:**
- Consumes: Task 7, Task 9 (`TaskListWidgetView`, `ThemedBackground`, `ThemedCheckbox`), Task 10 (`ToggleTaskIntent`, `WidgetFilterEntity`, `ThemeEntity`), `ThemeAccess.effectiveTheme`, `DeepLink`.
- Produces:
  - `TaskListConfigurationIntent: WidgetConfigurationIntent`:
    - `title "Tasks"`.
    - `@Parameter(title: "Show") var filter: WidgetFilterEntity?`.
    - `@Parameter(title: "Theme") var theme: ThemeEntity?`.
  - `struct TaskListEntry: TimelineEntry { date; model: WidgetViewModel; theme: Theme }`.
  - `struct TaskListProvider: AppIntentTimelineProvider`:
    - `placeholder` and `snapshot` use `SampleTasks`.
    - `timeline` loads `repository().snapshots()` on the MainActor. If that throws, it renders an empty model titled "Open Todo1 to finish setup".
    - Policy: `.after(WidgetLayout.nextRefreshDate)`.
  - `struct TaskListWidget: Widget`:
    - `kind = "TaskListWidget"`.
    - `AppIntentConfiguration` with `.containerBackground(for: .widget) { ThemedBackground(theme:) }`.
    - Families small, medium and large.
    - `configurationDisplayName("Tasks")`; description "See, add and tick off tasks right from your Home Screen."
  - Widget behaviour:
    - Checkboxes are `Button(intent: ToggleTaskIntent(taskID:))` with `.buttonStyle(.plain)`.
    - The add link is `DeepLink.quickAdd(filter).url`.
    - The task link is `DeepLink.task(id).url`. Small widgets pass `taskLink` returning nil and set `.widgetURL(DeepLink.quickAdd(filter).url)`.
    - A locked fallback sets `.widgetURL(DeepLink.themes.url)` on the footer caption via `Link`.
  - `Info.plist`: `NSExtension.NSExtensionPointIdentifier = com.apple.widgetkit-extension`, `UIAppFonts` listing the 4 font files.

- [ ] **Step 1:** Implement.
- [ ] **Step 2:** Run `scripts/parse-check.sh`. Expected: exit 0. Run `plutil`-equivalent validation with `python3 -c "import plistlib,sys;plistlib.load(open(sys.argv[1],'rb'))" <file>` for each plist/entitlements/xcprivacy. Expected: no exception.
- [ ] **Step 3:** Commit `feat(widget): interactive themed task-list widget`.

### Task 12: App shell, home, quick add, editor, lists

**Files:** Create `App/Todo1App.swift`, `App/AppModel.swift`, `App/TargetRole.swift` (`.app`), `App/AppShortcuts.swift`, and in `App/Views/`: `RootView.swift`, `HomeView.swift`, `TaskRowView.swift`, `QuickAddSheet.swift`, `TaskEditorView.swift`, `ListsView.swift`, `UndoBanner.swift`

**Interfaces:**
- Consumes: TodoKit (all), `TaskRepository`, `ModelContainerFactory`, `ThemeStyle`/`ThemedTaskRow`/`ThemedCheckbox`/`ThemedBackground`, `AddTaskIntent`, `NotificationScheduler` (Task 14), `PurchaseManager` (Task 15), `ThemeGalleryView`/`OnboardingView`/`SettingsView`/`PaywallSheet` (Task 15).
- Produces:
  - `@MainActor @Observable final class AppModel`:
    - Properties: `let catalog = ThemeCatalog.bundled`, `let store = SharedStore.appGroup()`, `var preferences: AppPreferences`, `var entitlements: EntitlementState`, `var route: Route?`, `var homeFilter: TaskFilter = .all`.
    - `var appTheme: Theme { ThemeAccess.effectiveTheme(selectedID: preferences.appThemeID, catalog:, state: entitlements).theme }`.
    - `func updatePreferences(_ change: (inout AppPreferences) -> Void)`: saves and calls `IntentSupport.reloadWidgets()`.
    - `func handle(url: URL)`: `DeepLink` to `route`.
    - `func applyEntitlements(_ s: EntitlementState)`: saves to the store and reloads widgets if changed.
  - `enum Route: Identifiable, Hashable { case quickAdd(TaskFilter?), task(UUID), themes, paywall, settings, lists }`.
  - `Todo1App`:
    - Creates `ModelContainerFactory.shared(role: .app)`. On failure it shows a plain error view with "Restart the app".
    - Provides `.modelContainer`, the `AppModel` and the `PurchaseManager` (`configure()` in `init`).
    - Calls `FontRegistration.registerBundledFonts()`.
    - `.onOpenURL(perform: model.handle)`.
    - On `scenePhase == .active`: `purgeCompleted`, `ensureDefaultList` (after a 5-second delay on the first launch only, per spec section 5), `NotificationScheduler.shared.reschedule(...)`, `purchases.refresh()` and `IntentSupport.reloadWidgets()`.
    - Applies `.preferredColorScheme` from `appTheme.colorScheme` and `.tint(appTheme.accent.color)`.
  - `HomeView`:
    - A filter picker (All / Today / each list).
    - `@Query` of `TaskItem` mapped to snapshots, then `TaskGrouping.grouped` in a themed `List` with the Completed section collapsible.
    - Swipe right (leading) completes; swipe left (trailing) deletes, with `UndoBanner` for 4 s calling `repository.restore`.
    - A "+" floating button sets `route = .quickAdd(homeFilter)`.
    - Toolbar: Themes, Lists, Settings.
  - `QuickAddSheet(filter: TaskFilter?)`:
    - `@FocusState` focused on appear.
    - Chips: Today / Tomorrow / Date… / Time… / Repeat menu / List menu. The `.today` filter preselects Today; `.list(id)` preselects that list.
    - Submit (return) normalises the title, adds the task, clears the field, keeps focus, triggers a haptic and reloads widgets.
    - The first save with a time calls `NotificationScheduler.shared.requestAuthorizationIfNeeded(model:)`.
  - `TaskEditorView(taskID: UUID)`: all fields plus Delete.
  - `ListsView`: add, rename (alert), reorder (`onMove`), and delete with a confirmation dialog ("Delete list and its N tasks?").
  - `AppShortcuts: AppShortcutsProvider` with `AppShortcut(intent: AddTaskIntent(), phrases: ["Add a task in \(.applicationName)", "Add a task to \(.applicationName)", "New \(.applicationName) task"], shortTitle: "Add Task", systemImageName: "plus.circle")`. String parameters cannot appear in phrases, so the spec's `${title}` phrase is dropped by design; Siri asks for the title.

- [ ] **Step 1:** Implement.
- [ ] **Step 2:** Run `scripts/parse-check.sh`. Expected: exit 0.
- [ ] **Step 3:** Commit `feat(app): app shell, home, quick add, editor, lists`.

### Task 13: Xcode project, configuration, assets, CI

**Files:** Create `project.yml`, `Config/Base.xcconfig`, `App/Resources/Info.plist`, `App/Resources/Todo1.entitlements`, `App/Resources/PrivacyInfo.xcprivacy`, `App/Resources/Todo1.storekit`, `App/Resources/Assets.xcassets/{Contents.json, AppIcon.appiconset/{Contents.json, AppIcon-1024.png}, AccentColor.colorset/Contents.json}`, `.github/workflows/ios.yml`

**Interfaces:**
- `project.yml` (XcodeGen):
  - `name: Todo1`, `options.bundleIdPrefix: ai.shavastudios`, `deploymentTarget.iOS: "17.0"`.
  - `configFiles` uses `Config/Base.xcconfig`.
  - Settings: `SWIFT_VERSION: 5.0`, `TARGETED_DEVICE_FAMILY: 1`, `MARKETING_VERSION: 1.0.0`, `CURRENT_PROJECT_VERSION: 1`.
  - `packages`: `TodoCore` (`path: Packages/TodoCore`) and `RevenueCat` (`url: https://github.com/RevenueCat/purchases-ios-spm`, `from:` the latest 5.x tag found with `git ls-remote --tags`).
  - Target `Todo1` (application):
    - Sources: `App`, `Shared/Intents`, and `Shared/Fonts` as resources.
    - Dependencies: TodoKit, TodoData, TodoUI, RevenueCat, RevenueCatUI, and `Todo1Widget` (embed).
    - Entitlements: `App/Resources/Todo1.entitlements`.
  - Target `Todo1Widget` (app-extension):
    - Sources: `Widget`, `Shared/Intents`, and `Shared/Fonts` as resources.
    - Dependencies: TodoKit, TodoData, TodoUI.
  - Scheme `Todo1` has `run.storeKitConfiguration: App/Resources/Todo1.storekit`.
- `Config/Base.xcconfig`:
  - `DEVELOPMENT_TEAM =` (empty, filled on the Mac).
  - `REVENUECAT_API_KEY = appl_REPLACE_ME`.
  - `#include? "Local.xcconfig"`.
- App `Info.plist`:
  - `CFBundleURLTypes` with scheme `todo1`.
  - `UIBackgroundModes: [remote-notification]`.
  - `UIAppFonts` (4 files).
  - `RevenueCatAPIKey: $(REVENUECAT_API_KEY)`.
  - `ITSAppUsesNonExemptEncryption: false`.
  - `UILaunchScreen: {}`.
  - `CFBundleDisplayName: Todo1`.
  - Portrait only.
- App entitlements:
  - `com.apple.security.application-groups: [group.ai.shavastudios.todo1]`
  - `com.apple.developer.icloud-container-identifiers: [iCloud.ai.shavastudios.todo1]`
  - `com.apple.developer.icloud-services: [CloudKit]`
  - `aps-environment: development`
- App privacy manifest: `NSPrivacyTracking false`. Accessed API `NSPrivacyAccessedAPICategoryUserDefaults` with reasons `CA92.1` and `1C8F.1`. Collected data types: `NSPrivacyCollectedDataTypePurchaseHistory`, linked false, tracking false, purpose `AppFunctionality`.
- `Todo1.storekit`: a StoreKit configuration (JSON) containing:
  - Subscription group "Premium" with `premium_yearly`, P1Y, 4.99, and an introductory offer of a free trial for P1W.
  - Non-consumable `premium_lifetime` at 14.99.
- App icon: a 1024×1024 opaque PNG with no alpha. Minimalist design: an off-white background with a single bold black rounded checkbox and tick. Generated by a Python script that writes PNG bytes with `zlib` and `struct` (stdlib only). Verify with `file` that the output is 1024 x 1024 RGB.
- `.github/workflows/ios.yml`:
  - Runs on `macos-15`, triggered by push and workflow_dispatch.
  - Steps: checkout, `sudo xcode-select -s` to the newest `/Applications/Xcode_*.app`, `brew install xcodegen`, `xcodegen generate`, `cd Packages/TodoCore && swift test`, then `xcodebuild -scheme Todo1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`.

- [ ] **Step 1:** Write all the files and generate the icon.
- [ ] **Step 2:** Validate:
  - Every `.plist`, `.entitlements` and `.xcprivacy` loads with Python `plistlib`.
  - `project.yml` and `ios.yml` load with `python3 -c "import yaml"` if PyYAML is available, otherwise a JSON round-trip via `ruby -ryaml` if available. Skip with a note if neither exists.
  - `Todo1.storekit` loads with `json.load`.
  - The icon is 1024×1024 RGB.
- [ ] **Step 3:** Commit `build: XcodeGen project, entitlements, privacy manifests, StoreKit config, CI`.

### Task 14: Notifications

**Files:** Create `App/Services/NotificationScheduler.swift`

**Interfaces:**
- Consumes: `NotificationPlanner`, `TaskSnapshot`, `AppModel.updatePreferences`.
- Produces: `@MainActor final class NotificationScheduler`:
  - `static let shared`.
  - `func requestAuthorizationIfNeeded(model: AppModel) async`: requests `.alert, .sound, .badge` only once, records `hasAskedNotificationPermission`, and does nothing if already asked.
  - `func reschedule(tasks: [TaskSnapshot], enabled: Bool) async`:
    - Removes pending requests whose identifier has the prefix `NotificationPlanner.identifierPrefix`.
    - If enabled and authorised, adds `UNCalendarNotificationTrigger` requests (built from date components) for `NotificationPlanner.plan(tasks, now: .now)`, with `userInfo["deepLink"] = DeepLink.task(id).url.absoluteString`.
  - Also acts as `UNUserNotificationCenterDelegate`:
    - Shows banners in the foreground.
    - Tapping a notification routes through `AppModel.handle(url:)`.
    - `func attach(model: AppModel)` sets the delegate.

- [ ] **Step 1:** Implement.
- [ ] **Step 2:** Run `scripts/parse-check.sh`. Expected: exit 0.
- [ ] **Step 3:** Commit `feat(app): local reminder notifications`.

### Task 15: Purchases, paywall, theme gallery, onboarding, settings

**Files:** Create `App/Services/PurchaseManager.swift`, `App/Services/PaywallSheet.swift`, and in `App/Views/`: `ThemeGalleryView.swift`, `ThemePreviewView.swift`, `OnboardingView.swift`, `SettingsView.swift`

**Interfaces:**
- Consumes: `EntitlementState.from`, `ThemeAccess`, `AppModel`, `TaskListWidgetView`, `ThemedBackground`, `ThemedCheckbox`, `SampleTasks`, `WidgetViewModel`, `WidgetLayout`, `AppConstants`.
- Produces:
  - `@MainActor @Observable final class PurchaseManager`:
    - `var isConfigured = false`.
    - `func configure()`: reads `Bundle.main` `RevenueCatAPIKey`. If it is empty or contains `REPLACE_ME`, it logs and returns, and the app runs in free mode. Otherwise it calls `Purchases.configure(withAPIKey:)`.
    - `func start(model: AppModel)`: listens to `Purchases.shared.customerInfoStream` and calls `refresh`.
    - `func refresh(model: AppModel) async`:
      - `isPremium` is `customerInfo.entitlements[AppConstants.entitlementID]?.isActive == true`.
      - Metadata is `offerings.current?.metadata ?? [:]`.
      - Then `model.applyEntitlements(.from(...))`.
      - On error it keeps the last stored state.
    - `func restore(model:) async -> String`: returns a user-facing result message.
  - `struct PaywallSheet: View`: RevenueCatUI `PaywallView(displayCloseButton: true)` with `onPurchaseCompleted` / `onRestoreCompleted` calling `refresh` and dismissing. If not configured, it shows a fallback "Purchases unavailable right now" view.
  - `ThemeGalleryView`:
    - A 2-column grid in `ordered(by: entitlements.themeOrder)` order.
    - Each cell is a `TaskListWidgetView` at medium size with `SampleTasks` over `ThemedBackground`, clipped to a 22pt rounded rect, with `.allowsHitTesting(false)` and a lock badge if locked.
    - Tapping an unlocked theme sets `preferences.appThemeID`. Tapping a locked theme pushes `ThemePreviewView`, which shows the large preview and an "Unlock all themes" button that sets `route = .paywall`.
    - A footer explains per-widget themes: long-press widget → Edit Widget → Theme.
  - `OnboardingView`: a 3-page `TabView` (value prop; pick a theme with a mini gallery; add-widget steps). "Get started" sets `hasCompletedOnboarding`. It is presented with `fullScreenCover` from `RootView` when false.
  - `SettingsView` sections:
    - **Premium:** status; Upgrade (`route = .paywall`), or a Manage Subscription button using `.manageSubscriptionsSheet`.
    - **Restore Purchases**, with an alert showing the result.
    - **Notifications** toggle, which updates preferences and triggers a reschedule.
    - **iCloud:** `CKContainer(identifier:).accountStatus()` shows "Syncing with iCloud" or "iCloud unavailable — tasks stay on this iPhone".
    - **Widget how-to.**
    - **Legal:** Privacy Policy and Terms links from `AppConstants`.
    - **Version.**

- [ ] **Step 1:** Implement.
- [ ] **Step 2:** Run `scripts/parse-check.sh`. Expected: exit 0.
- [ ] **Step 3:** Commit `feat(app): RevenueCat paywall, theme gallery, onboarding, settings`.

### Task 16: Release documents and legal pages

**Files:** Create `docs/MAC_SETUP.md`, `docs/LAUNCH_CHECKLIST.md`, `docs/appstore/metadata.md`, `site/privacy.html`, `site/terms.html`, `README.md`

**Content requirements:**
- **`MAC_SETUP.md`:** numbered steps for the friend's Mac.
  1. Install Xcode (latest) and `brew install xcodegen`.
  2. Clone the repo and create `Config/Local.xcconfig` with `DEVELOPMENT_TEAM` and `REVENUECAT_API_KEY`.
  3. Run `xcodegen generate` and open `Todo1.xcodeproj`.
  4. Under Signing & Capabilities, choose the team for both targets and confirm App Groups and iCloud (CloudKit).
  5. Run `cd Packages/TodoCore && swift test`.
  6. Run on a device: add the widget, tick a task, tap "+".
  7. StoreKit test via the scheme config.
  8. Product → Archive → Distribute → App Store Connect.
  9. Troubleshooting: a signing error for App Group or iCloud usually means the identifiers have not been created yet; enable automatic signing.
- **`LAUNCH_CHECKLIST.md`:**
  - **Developer portal:** IDs, App Group, iCloud container; deploy the CloudKit schema to Production after the first run.
  - **App Store Connect:** app record, Small Business Program, products exactly as in Global Constraints, subscription group localisation, review screenshot of the paywall.
  - **RevenueCat:** project, App Store app with the in-app purchase key, entitlement `premium`, offering `default` with `$rc_annual` and `$rc_lifetime`, paywall template, metadata `{"free_theme_count":3,"theme_order":[]}`.
  - **Changing prices later:** the 5 ways from spec section 9.
  - **App Privacy answers.**
  - **Privacy and Terms:** host the `site/` pages at the URLs in `AppConstants`, or change those constants.
  - **Review notes text.**
  - **TestFlight pass list:** Review Focus items 1–5, the widget in light, dark and tinted modes, and a trial purchase in sandbox.
- **`metadata.md`:** a working-name note (pick a final name; avoid "SplenDO"), subtitle (≤30 characters), promotional text, description, keywords (≤100 characters), what's new, support URL placeholder note, and review notes.
- **`privacy.html`:** no account; tasks stored on the device and in the user's private iCloud; purchases processed by Apple and RevenueCat (anonymous ID); no ads or tracking; contact email `singh.tejash@shavastudios.ai`.
- **`terms.html`:** subscription terms (auto-renew, cancel in Settings at least 24h before renewal, trial converts), and a reference to the Apple standard EULA.
- **`README.md`:** what the app is, the repo layout, how to run tests (Linux Docker / Mac), and links to the docs.

- [ ] **Step 1:** Write the files.
- [ ] **Step 2:** Check that every identifier and price in the docs matches Global Constraints (grep for `4.99`, `14.99`, `group.ai.shavastudios.todo1`).
- [ ] **Step 3:** Commit `docs: Mac setup, launch checklist, App Store metadata, legal pages`.

---

## Execution notes

- Tasks 2–7 are independent once Task 1 is done; run them in parallel, each with its own `SWIFT_SCRATCH`.
- Tasks 8–16 depend only on the Interfaces blocks above (not on each other's bodies), so they can run in parallel after 2–7. Tasks 12 and 15 share `AppModel` through its Interfaces block, and Task 12 owns `AppModel.swift`.
- The Apple-only code cannot be type-checked on Linux. After implementation, an integration review must check every cross-file symbol against these Interfaces blocks and every Apple API against iOS 17 availability, then fix the findings. The first real compile is on the Mac or the GitHub Actions macOS runner (Task 13).
