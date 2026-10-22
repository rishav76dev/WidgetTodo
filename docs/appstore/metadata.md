# App Store metadata

Copy each block below into App Store Connect. The character limits are Apple's. Each section shows the current count.

Prices aren't mentioned anywhere in this copy on purpose. They can change from the dashboards (see LAUNCH_CHECKLIST, section 4), and the App Store shows the live prices anyway.

---

## App name (max 30 characters)

"Todo1" is only a **working name**. Pick the final public name before you create the App Store Connect record.

**Rules for the name:**

- It must be original. Don't use "SplenDO" or anything close to it, and don't use any other app's or company's trademark.
- App Store names are unique. Type your choice into App Store Connect → **New App** to check that it's free.
- A short brand plus a descriptive word ranks best, for example "Name: Widget To-Do".

**Ideas to check:**

- Tickwise
- Inkdone
- Checkmark Widget To-Do
- Quiet List
- Donebox

If the public name isn't "Todo1", also change the following:

1. `CFBundleDisplayName` in `App/Resources/Info.plist`. This is the name under the icon, and it's also what Siri hears in "Add a task in …".
2. The subscription group display name in App Store Connect.
3. The word "Todo1" in `site/privacy.html` and `site/terms.html`.

## Subtitle (max 30 characters)

```
Widget to-do list & themes
```

(26 characters)

## Promotional text (max 170 characters, can be changed at any time without review)

```
Tick off tasks right from your home screen. 12 striking minimalist themes for your widget and app. Syncs with iCloud, no account needed.
```

(136 characters)

## Description (max 4000 characters)

```
Your to-do list, right on your home screen.

Add a task in two taps, tick it off without opening the app, and make your widget look exactly the way you like with a collection of striking minimalist themes.

THE WIDGET IS THE APP
• Interactive small, medium and large widgets: tap the checkbox to complete a task
• Tap + on the widget to jump straight into quick add with the keyboard ready
• Choose which list each widget shows: All, Today, or any of your lists
• Give every widget its own theme

THEMES
12 hand-made themes restyle both the widget and the app: Paper, Midnight, Mono Mint, Terminal, Brutalist, Receipt, Swiss, Blueprint, Pocket 8-bit, Neon, Zen and Sticky Note. Every theme also looks right on dark and tinted home screens.

FAST AND SIMPLE
• Quick add keeps the sheet open, so you can type a whole list in seconds
• Due dates, times and repeats: daily, weekdays, weekly, monthly, yearly
• Reminders at the time you choose
• Tasks grouped into Overdue, Today, Tomorrow, Upcoming and No date
• Swipe to complete or delete, with undo
• Add tasks with Siri, Shortcuts or the Action button: "Add a task in Todo1"

PRIVATE BY DESIGN
• No account, no sign-up, no ads, no tracking
• Your tasks stay on your iPhone and sync through your own private iCloud

PREMIUM
The to-do list, widgets, reminders, sync and Siri are free. Three themes are free too. Premium unlocks every theme, as a yearly subscription with a free trial or a one-time lifetime purchase.

The subscription renews automatically unless you cancel it at least 24 hours before the end of the current period. A free trial, if offered, turns into a paid subscription when it ends unless you cancel before then. You can manage or cancel the subscription in your Apple ID settings.

Terms of Use (EULA): https://shavastudios.ai/todo1/terms
Privacy Policy: https://shavastudios.ai/todo1/privacy
```

If the final name isn't "Todo1", change "Add a task in Todo1" in the description to match.

## Keywords (max 100 characters, comma-separated, no spaces)

```
todo,tasks,checklist,reminder,planner,aesthetic,minimal,productivity,routine,daily,organizer,agenda
```

(99 characters)

- Words that are already in the name or subtitle ("widget", "list", "themes") count anyway, so they are left out here.
- Don't add competitor or brand names.

## What's New (version 1.0.0)

```
First release: interactive home-screen widgets, 12 themes, quick add, repeating tasks, reminders, iCloud sync and Siri.
```

## URLs

| Field | Value |
|---|---|
| Privacy Policy URL | `https://shavastudios.ai/todo1/privacy` |
| Support URL | **Placeholder.** Use `https://shavastudios.ai/todo1/support` once that page exists. It must load and show a way to contact you, for example "Email singh.tejash@shavastudios.ai". See LAUNCH_CHECKLIST, section 6. |
| Marketing URL | Optional; leave it empty |
| License Agreement | Apple's standard EULA (the default) |

## Review notes

Paste this into App Store Connect → the version → **App Review Information** → **Notes**. Replace "Todo1" if the name changed.

```
Thank you for reviewing Todo1.

ACCOUNT: No account or sign-in is needed. There is no demo account.

WHAT IS FREE: All core to-do features are free with no limits: lists, tasks, due dates and times, repeating tasks, reminders, iCloud sync, the home-screen widgets (small, medium, large), and Siri / Shortcuts. Three themes are also free. Premium only unlocks the remaining visual themes; it does not unlock any functionality.

HOW TO ADD THE WIDGET:
1. Open the app once and add a task with the + button.
2. Go to the Home Screen, touch and hold an empty area, tap Edit > Add Widget.
3. Search for "Todo1", pick a size, tap Add Widget.
4. Tap a task's checkbox on the widget to complete it without opening the app. Tap + on the widget to open quick add.
5. To choose the list or theme for a widget: touch and hold the widget > Edit Widget.

HOW TO TEST PREMIUM (sandbox):
- In the app, tap the gear icon (top right of the home screen) and tap "Upgrade to Premium". Or tap the palette icon (Themes), tap any theme with a lock, then "Unlock all themes".
- Products: "premium_yearly" (auto-renewable, 1 year, with a 1-week free introductory trial) and "premium_lifetime" (non-consumable).
- After purchase, all themes unlock in the app and in the widget's theme picker.
- Restore Purchases is in Settings (gear icon). Manage Subscription appears there while a subscription is active.
- The paywall shows the price, the period, what is charged after the trial, auto-renewal terms, Restore Purchases, and links to the Terms of Use and Privacy Policy.

SIRI: Say "Add a task in Todo1"; Siri asks what to add.

PRIVACY: Tasks are stored on the device and in the user's private iCloud database. We have no servers. Purchases are processed by Apple; RevenueCat verifies them using an anonymous ID. No ads, no tracking.
```
