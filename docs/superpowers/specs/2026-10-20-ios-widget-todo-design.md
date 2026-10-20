# iOS Widget To-Do App — Design Spec

- **Date:** 2026-10-20
- **Status:** Draft, awaiting review
- **Codename:** Todo1 (the public App Store name is chosen in W7; it must not reference SplenDO)

## 1. Goal

A native iPhone to-do app whose main feature is a home-screen widget for viewing, adding and completing tasks, plus a catalogue of striking minimalist themes that restyle both the widget and the app. It earns money through a premium unlock (a yearly subscription with a 1-week free trial, or a lifetime purchase). Prices and paywall offers can change after launch without an app update.

**Reference product:** SplenDO "To Do List" for Android (`com.splendapps.splendo`). We use it only as a functional reference: lists, tasks with due date and time, repeating tasks, reminders, a list widget with a "+" button. We copy no code, assets, name, copy text or icons (App Review Guideline 5.2). Our themes and visual identity differentiate the app (Guideline 4.3).

**Success criteria for v1**
1. A user can add a task in two taps from the home screen ("+" opens the quick-add sheet with the keyboard up), or with no taps through Siri, Shortcuts or the Action button.
2. A user can complete a task from the widget without opening the app (iOS 17 interactive widget).
3. 12 themes ship. The first N (default 3, set remotely) are free; the rest need premium.
4. The paywall, products, prices, trial and free-theme count can all change from dashboards (App Store Connect and RevenueCat) without shipping a new binary.
5. Tasks sync across the user's devices through iCloud, with no account or login.
6. The app passes App Review on its first or second submission.

## 2. Decisions

| Topic | Decision | Reason |
|---|---|---|
| Platform | iPhone only, minimum **iOS 17.0** | SwiftData and interactive widgets need iOS 17 |
| Stack | **100% Swift / SwiftUI**, no React Native | The widget, App Intents and StoreKit are native-only; one codebase; the in-app theme preview is the real widget view |
| Data | **SwiftData** in an App Group container, synced with **CloudKit private database** | $0 running cost, no login, no backend |
| Backend | **None** | Not needed for one-user sync. Accounts would add Sign in with Apple, in-app account deletion (5.1.1(v)), GDPR work and hosting cost |
| Payments | **RevenueCat** (native SDK + RevenueCatUI remote paywalls) on top of StoreKit | Remote offerings, paywall templates, trial eligibility, A/B experiments |
| Ads | None | Fits the premium minimalist brand and keeps the privacy label simple |
| Build | Xcode on macOS (required by Apple); CI optional (Xcode Cloud) | iOS apps cannot be built or signed on Linux |

### Identifiers (assumed; change in W0 if you prefer others)
- Bundle ID: `ai.shavastudios.todo1`, widget `ai.shavastudios.todo1.widget`
- App Group: `group.ai.shavastudios.todo1`
- iCloud container: `iCloud.ai.shavastudios.todo1`
- URL scheme: `todo1://`

## 3. Running costs

| Item | Cost |
|---|---|
| Apple Developer Program | $99 / year (required to publish at all) |
| iCloud / CloudKit private database | **$0.** Data counts against each user's own iCloud storage, not the developer's |
| RevenueCat | Free up to $2,500 monthly tracked revenue, then about 1% of it (check current pricing at signup) |
| Apple commission | 15% under the Small Business Program (under $1M/yr; apply in App Store Connect), otherwise 30% |
| Backend | $0 (none) |

## 4. Architecture

```
Xcode project (iOS 17+)
├─ Todo1 (app target, SwiftUI)
│   Screens · Paywall (RevenueCatUI) · Notifications scheduler · Deep-link router
├─ Todo1Widget (WidgetKit extension)
│   TaskListWidget (small/medium/large) · ToggleTaskIntent · widget config intent
└─ Packages/Core (local Swift package, linked into BOTH targets)
    Models (SwiftData) · TaskRepository · RepeatRule math · Grouping (Overdue/Today/…)
    Theme engine (JSON → ThemeStyle) · Themed views (rows, header, background)
    EntitlementCache (App Group UserDefaults) · DeepLink enum
    AddTaskIntent + AppShortcutsProvider (Siri / Shortcuts / Action button)
App Group container: SwiftData store + shared UserDefaults
```

**Data flow**
- The app and the widget open the **same SwiftData store** in the App Group container.
- Only the **app** enables CloudKit mirroring (`cloudKitDatabase: .private(...)`). The widget opens the store with `cloudKitDatabase: .none` and reads and writes it locally. The app picks up widget writes on its next launch or foreground and syncs them. **Spike S1 (first task in W1) verifies this.** Fallback if widget writes are not mirrored reliably: widget intents append operations to a shared `pending-ops.json`, which the app applies on foreground; the widget shows the pending state optimistically.
- After any change, the app calls `WidgetCenter.shared.reloadAllTimelines()`. Widget intents reload their own timelines automatically.
- Entitlements: the app writes `isPremium`, `freeThemeCount` and `themeOrder` to App Group UserDefaults whenever RevenueCat `CustomerInfo` or offerings change. The widget only reads this cache.

**Deep links**
- `todo1://quick-add?list=<listID|all|today>` opens the quick-add sheet with the keyboard focused
- `todo1://task/<taskID>` opens the task editor
- `todo1://themes` opens the theme gallery

## 5. Data model (SwiftData, CloudKit-compatible)

CloudKit rules: every attribute is optional or has a default, every relationship is optional, and there is no `@Attribute(.unique)`.

```swift
@Model final class TaskList {
  var id: UUID = UUID()
  var name: String = ""
  var sortIndex: Int = 0
  var createdAt: Date = Date()
  @Relationship(deleteRule: .cascade, inverse: \TaskItem.list) var tasks: [TaskItem]? = []
}

@Model final class TaskItem {
  var id: UUID = UUID()
  var title: String = ""
  var notes: String = ""
  var dueDate: Date?            // nil = no date
  var hasDueTime: Bool = false  // false = all-day
  var repeatRuleRaw: String = "none" // none|daily|weekdays|weekly|monthly|yearly
  var isCompleted: Bool = false
  var completedAt: Date?
  var sortIndex: Int = 0
  var createdAt: Date = Date()
  var list: TaskList?
}
```

**Behaviour rules**
- **Repeating tasks:** completing one moves its `dueDate` forward to the next occurrence and leaves it incomplete. No new record is created, which avoids duplicates under sync.
- **Grouping:** Overdue, Today, Tomorrow, Upcoming, No date. Completed tasks sit in a collapsed section.
- **Cleanup:** completed tasks are deleted automatically 30 days after `completedAt`. This runs on app launch.
- **Default list:** a "Personal" list is created on first launch if no lists exist after the initial iCloud sync (wait up to 5 s for the first import to avoid duplicate default lists).

## 6. App screens and flows

1. **Onboarding (first launch, 3 pages):** (a) value proposition, (b) pick a theme (free themes selectable, locked ones previewable), (c) "Add the widget" instructions with an animation. No permission prompts during onboarding.
2. **Home:** a list switcher at the top (All, Today, each list), tasks grouped as in section 5, a "+" floating button. Swipe right to complete, swipe left to delete (undo through a snackbar). Tap a task to open the editor.
3. **Quick-add sheet:** the title field is focused on open. Chips for Today, Tomorrow, Pick date, Time, Repeat and List. Return adds the task and **keeps the sheet open** with the field cleared, for rapid entry. Swipe down closes it.
4. **Task editor:** title, notes, date, time, repeat, list, delete.
5. **Lists:** create, rename, reorder, delete (with a confirmation that its tasks are deleted too).
6. **Theme gallery:** a grid of **real widget views** rendered with sample tasks in each theme. Lock badge on premium themes. Tapping a free theme applies it to the app and becomes the default for new widgets. Tapping a locked theme opens a full preview and a "Unlock" button that leads to the paywall. A note explains how to set a different theme per widget (long-press the widget, then Edit Widget).
7. **Paywall:** RevenueCatUI `PaywallView` for the current offering. It opens from locked themes, from Settings, and from the onboarding theme page.
8. **Settings:** Premium status and Manage Subscription (`manageSubscriptionsSheet`), Restore Purchases, iCloud sync status, Notifications on or off, Widget how-to, Privacy Policy, Terms of Use (EULA), version.

**Notifications:** local `UNUserNotificationCenter` notifications at the due time, for tasks with `hasDueTime`. Permission is requested **the first time a user saves a task with a time**, not at launch. Schedules are rebuilt after any change and on launch. iOS limits apps to 64 pending notifications, so we schedule the soonest 60.

## 7. Widget

- **Families:** `systemSmall`, `systemMedium`, `systemLarge`. Lock-screen widgets come in v1.1.
- **Configuration (`AppIntentConfiguration`):** `list` (All / Today / a specific list, through an `AppEntity` query) and `theme` (a `ThemeEntity` query listing all themes; locked ones are suffixed with 🔒).
- **Layouts:**
  - **Small:** list name, open-task count, the next task title, and a "+" corner button.
  - **Medium:** a header (list name and "+") plus up to 3 rows, then "+N more".
  - **Large:** a header plus up to 7 rows, then "+N more".
  - **Row:** a checkbox `Button(intent: ToggleTaskIntent(taskID))`, the title, and a due label (overdue in the theme's `overdue` colour). The row body is a `Link` to `todo1://task/<id>`.
  - **Header "+":** a `Link` to `todo1://quick-add?list=<id>`.
  - **Empty state:** "All clear" in the theme's style, plus "+".
- **Timeline:** a single entry now, with refresh `.after(nextRelevantDate)`. That is the earliest of the next midnight and the next task due time (when overdue styling changes), capped at 1 hour.
- **Locked theme fallback:** if a widget's theme is locked (no premium, or a trial or subscription has expired), the widget renders the default free theme with a small "Theme locked: tap to unlock" footer linking to `todo1://themes`. The user's choice is kept and comes back on resubscribe.
- **Rendering modes:** every theme must look correct in `fullColor`, `accented` (tinted home screen) and `vibrant` modes. Theme backgrounds use `containerBackground(for: .widget)` so iOS can remove them in tinted or clear modes, and checkboxes and text use `widgetAccentable()` where appropriate.
- **Siri, Shortcuts and Action button:** `AddTaskIntent(title: String, list: ListEntity?)` adds a task without opening the app. It is exposed through `AppShortcutsProvider` with the phrases "Add a task in ${applicationName}" and "Add ${title} to ${applicationName}". When `title` is missing, the system prompts for it.

## 8. Theme engine and catalogue

**Theme file:** `Core/Resources/Themes/<id>.json`, decoded into a `Theme` struct.
```json
{
  "id": "terminal",
  "name": "Terminal",
  "background": { "type": "solid", "colors": ["#000000"] },
  "textPrimary": "#33FF66", "textSecondary": "#1F9940",
  "accent": "#33FF66", "overdue": "#FF5555",
  "font": { "family": "IBMPlexMono", "weight": "regular", "scale": 1.0, "case": "lower" },
  "header": { "style": "prompt", "prefix": "> " },
  "row": { "style": "plain", "divider": "none", "spacing": 6 },
  "checkbox": { "style": "bracket" },
  "cornerRadius": 0,
  "padding": 14
}
```
- Enumerated styles: background `solid|gradient|image`. Header `plain|bold|prompt|stamp`. Row `plain|divider|card|dashed`. Checkbox `circle|square|bracket|strike|dot`. Case `none|upper|lower`.
- Unknown values fall back to the defaults, and a malformed theme file falls back to "Paper". Unit tests cover this.
- **Free vs locked:** themes are ordered by `themeOrder` (bundled default, replaceable remotely). The first `freeThemeCount` themes are free.
- **Fonts:** system fonts (SF Pro, SF Mono, New York) plus fonts under the **SIL Open Font License** only, bundled in the shared package so the widget can use them. Every bundled font's licence file is included.

**Launch catalogue (12)**

| # | Theme | Idea |
|---|---|---|
| 1 | Paper *(free)* | Off-white, black ink, New York serif, thin dividers |
| 2 | Midnight *(free)* | Pure black, white SF, dot checkboxes |
| 3 | Mono Mint *(free)* | Pale mint, dark green SF Mono, square checkboxes |
| 4 | Terminal | Green phosphor monospace, `[ ]` / `[x]`, `> ` prompt header |
| 5 | Brutalist | Huge bold uppercase, thick black borders, safety-yellow background |
| 6 | Receipt | Thermal-paper white, dashed rows, monospace, "TOTAL: 5 ITEMS" footer |
| 7 | Swiss | Helvetica-style grid, red accent bar, strict alignment |
| 8 | Blueprint | Blue grid pattern, white technical font |
| 9 | Pocket 8-bit | 4-shade green pixel font (Press Start 2P, OFL) |
| 10 | Neon | Black background, glowing magenta and cyan text |
| 11 | Zen | One task at a time, huge whitespace, tiny count |
| 12 | Sticky Note | Yellow note, handwritten-style OFL font, strike-through checkboxes |

## 9. Monetization and remote pricing

**App Store Connect**
- Subscription group "Premium" with `premium_yearly`: auto-renewable, 1 year, **$4.99**, and an introductory offer of a **free trial, 1 week**.
- `premium_lifetime`: non-consumable, **$14.99**. This lifetime price is our proposal and can be changed in App Store Connect at any time.
- Small Business Program enrolment.

**RevenueCat**
- Entitlement `premium`, attached to both products.
- Offering `default` with packages `$rc_annual` and `$rc_lifetime`, and a RevenueCatUI paywall template.
- Offering metadata: `{ "free_theme_count": 3, "theme_order": ["paper", "midnight", ...] }`, read by the app and cached in the App Group. The bundled defaults apply if the app is offline or has never fetched offerings.

**How prices change without an app update**
1. **Same product, new price:** change the price schedule in App Store Connect. Existing subscribers can keep their old price.
2. **Different product or trial:** create a new product in App Store Connect. After the first IAP approval, IAPs can be submitted for review on their own, with no new binary. Then point the RevenueCat offering at it.
3. **Different paywall design, copy or layout:** edit it in the RevenueCat paywall editor.
4. **A/B testing prices:** RevenueCat Experiments between two offerings.
5. **Free-theme count or theme order:** edit the offering metadata.

**Rules**
- Trial eligibility comes from RevenueCat's `checkTrialOrIntroDiscountEligibility`. Eligible users see "Start 1-week free trial". Others see the price.
- The paywall must show (Guideline 3.1.2): price and period, what is charged after the trial, auto-renew terms, Restore Purchases, and links to Terms (EULA) and Privacy Policy. RevenueCatUI templates cover this, and we verify it in W5.
- **When premium ends:** the app theme and every widget fall back to the default free theme (Paper). The user's choices stay stored and come back on resubscribe.
- No RevenueCat account login. RevenueCat assigns an anonymous app user ID, and purchases restore through the Apple ID.

## 10. App Store compliance checklist

- `PrivacyInfo.xcprivacy` for the app and widget: UserDefaults required-reason API (`CA92.1` for app-only defaults, `1C8F.1` for App Group defaults). RevenueCat ships its own manifest.
- App Privacy label: purchase history, and possibly identifiers (anonymous ID), as declared in RevenueCat's App Store privacy guidance at submission time. Data is not used for tracking, so App Tracking Transparency is not needed.
- `ITSAppUsesNonExemptEncryption = NO`.
- No accounts, so the account-deletion rule does not apply.
- Privacy Policy URL and Terms of Use (EULA) URL hosted publicly (a static page is enough) and linked in-app and in App Store metadata.
- An original name, icon and screenshots, with no SplenDO assets and no third-party trademarks in theme names.
- Review notes: explain how to add the widget, how to test the paywall in sandbox, and that premium unlocks themes only. Core to-do features stay free, so the app is not just a paywall.
- Build with the Xcode version and SDK Apple currently requires for submissions.

## 11. Testing

- **Core unit tests (Swift Testing):**
  - Repeat-rule date maths, including month-end, leap years and time zones.
  - Task grouping around midnight.
  - Theme JSON decoding and fallbacks.
  - Entitlement gating: the free count, expiry fallback, and offline defaults.
  - Deep-link parsing.
  - The 30-day cleanup.
- **Widget:** Xcode previews for every theme × family × rendering mode, plus a manual check of the widget toggle and quick-add deep link on a device.
- **Purchases:** a local `.storekit` configuration file to test the trial, renewal, expiry, refund and lifetime flows in the simulator (with accelerated time). Then the RevenueCat sandbox, then TestFlight.
- **Sync (manual):** two devices on one Apple ID. Add, complete and delete on each, including from the widget (Spike S1).
- **Accessibility:** Dynamic Type in the app; VoiceOver labels on widget rows and checkboxes; contrast checked per theme in the app.

## 12. Work streams

| ID | Work stream | Depends on | Output |
|---|---|---|---|
| W0 | **Accounts and setup:** Apple Developer Program, bundle IDs, App Group, iCloud container, App Store Connect app record, RevenueCat project, Mac with Xcode | — | Signed empty app runs on a device |
| W1 | **Core package:** models, repository, repeat and grouping logic, entitlement cache, deep links; **Spike S1** | W0 | Tested `Core` package |
| W2 | **App UI:** onboarding, home, quick-add, editor, lists, settings, notifications | W1 | Usable to-do app |
| W3 | **Widget:** timeline, three sizes, toggle intent, "+" deep link, config intent, locked fallback | W1 | Interactive widget |
| W4 | **Themes:** engine, 12 theme JSONs, OFL fonts, gallery with real widget previews, rendering modes | W1 (engine); W3 (widget previews) | Theme catalogue |
| W5 | **Monetization:** App Store Connect products, RevenueCat offering and paywall, gating, restore, remote metadata, `.storekit` tests | W1, W4 | Working paywall and trial |
| W6 | **Sync and Siri:** CloudKit enablement, sync status UI, `AddTaskIntent` and App Shortcuts | W1, W3 | Cross-device sync, voice add |
| W7 | **Release:** name, icon, screenshots, privacy policy and EULA pages, privacy manifest and label, TestFlight beta, submission | All | App live on the App Store |

W2, W3 and W5 can run in parallel once W1 is done.

## 13. Out of scope for v1 (candidates for v1.1)

Lock-screen and StandBy widgets, Control Center control (iOS 18), a custom theme editor, a daily summary notification, iPad layout, Android, shared and collaborative lists, remotely downloadable themes, subtasks, priorities.
