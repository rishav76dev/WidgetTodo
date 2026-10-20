# Launch checklist

This is everything the **app owner** does outside the code to get Todo1 onto the App Store. Most of it happens in web dashboards and doesn't need a Mac. Work through it top to bottom and tick each box as you go.

These values must match the code exactly:

| What | Value |
|---|---|
| App bundle ID | `ai.shavastudios.todo1` |
| Widget bundle ID | `ai.shavastudios.todo1.widget` |
| App Group | `group.ai.shavastudios.todo1` |
| iCloud container | `iCloud.ai.shavastudios.todo1` |
| URL scheme | `todo1` |
| RevenueCat entitlement | `premium` |
| Yearly product | `premium_yearly`: auto-renewable, 1 year, **$4.99**, 1-week free trial, group "Premium" |
| Lifetime product | `premium_lifetime`: non-consumable, **$14.99** |
| Free themes by default | 3 (Paper, Midnight, Mono Mint) |
| Privacy Policy URL in the app | `https://shavastudios.ai/todo1/privacy` |
| Terms of Use URL in the app | `https://shavastudios.ai/todo1/terms` |
| Support contact | `singh.tejash@shavastudios.ai` |

---

## 0. Accounts and agreements

- [ ] Enrol in the [Apple Developer Program](https://developer.apple.com/programs/enroll/) ($99/year).
  - Enrolling as an **organisation** (Shava Studios) shows the company name as the seller. It needs a D-U-N-S number and can take several days.
  - Enrolling as an **individual** shows your personal name.
- [ ] In App Store Connect, open **Business** (called **Agreements, Tax, and Banking** on older layouts).
  - Accept the **Paid Apps** agreement.
  - Fill in tax and bank details.
  - In-app purchases don't load, even in testing, until the Paid Apps agreement is active.
- [ ] Apply to the [App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/). It cuts Apple's commission from 30% to 15%.
- [ ] Create a free account at [RevenueCat](https://www.revenuecat.com).
- [ ] Give the person with the Mac access to the team. Go to App Store Connect → **Users and Access** → **+**, enter their Apple ID, and choose the role **Admin**. See MAC_SETUP, step 0.

## 1. Developer portal (Certificates, Identifiers & Profiles)

Xcode's automatic signing usually creates all of these the first time the app is built. Check them here, and create any that are missing. Go to [developer.apple.com/account](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles** → **Identifiers**.

- [ ] **App Group**
  1. Click **+** → **App Groups**.
  2. Enter the description "Todo1" and the identifier `group.ai.shavastudios.todo1`.
- [ ] **iCloud container**
  1. Click **+** → **iCloud Containers**.
  2. Enter the description "Todo1" and the identifier `iCloud.ai.shavastudios.todo1`.
- [ ] **App ID for the app**
  1. Click **+** → **App IDs** → **App**.
  2. Enter the description "Todo1" and the explicit Bundle ID `ai.shavastudios.todo1`.
  3. Enable these capabilities:
     - **App Groups:** click **Configure** and tick `group.ai.shavastudios.todo1`.
     - **iCloud:** choose **Include CloudKit support**, click **Configure** and tick `iCloud.ai.shavastudios.todo1`.
     - **Push Notifications.**
     - **In-App Purchase**, which is on by default.
- [ ] **App ID for the widget**
  1. Click **+** → **App IDs** → **App**.
  2. Enter the description "Todo1 Widget" and the Bundle ID `ai.shavastudios.todo1.widget`.
  3. Enable **App Groups**, configured with `group.ai.shavastudios.todo1`.
- [ ] **Deploy the CloudKit schema to Production.** Do this before the first TestFlight build, because TestFlight and App Store builds use the Production database.
  1. First, run a development build from Xcode on an iPhone signed in to iCloud. In it, create a list and a task with a date, notes and a repeat rule, then complete it. This makes the app create its record types (`CD_TaskList`, `CD_TaskItem`) in the **Development** environment.
  2. Open the [CloudKit Console](https://icloud.developer.apple.com) → **CloudKit Database** → container `iCloud.ai.shavastudios.todo1`.
  3. In the Development environment, check that both record types exist.
  4. Click **Deploy Schema Changes…** → **Deploy**.
  5. If a later version adds model fields, deploy again before releasing it.
  6. Never rename or delete fields that are already in Production. Only add new ones.

## 2. App Store Connect

### App record

- [ ] Go to [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App** and fill in:
  - Platform: **iOS**
  - Name: your final public name (see `docs/appstore/metadata.md`)
  - Primary language: English (U.S.)
  - Bundle ID: `ai.shavastudios.todo1`
  - SKU: `todo1`
  - User access: Full Access
- [ ] Open **App Information**:
  - Category: **Productivity**. A secondary category is optional, for example Lifestyle.
  - Content rights: the app contains no third-party content.
  - Age rating: answer "None" to every question, which gives **4+**.
- [ ] Open **Pricing and Availability**:
  - Price: **Free**. The app is free to download, and Premium is an in-app purchase.
  - Availability: all countries, or the ones you choose.

### Subscription: premium_yearly

Go to your app → **Monetization** → **Subscriptions**.

- [ ] **Create the subscription group**
  1. Create a group with the reference name **Premium**.
  2. Add a group **localization** for English (U.S.), with the display name "Todo1 Premium" or "<Final name> Premium". Apple rejects subscriptions whose group has no localization.
- [ ] **Create the subscription**
  1. In the group, create a subscription with the reference name "Premium Yearly" and the Product ID `premium_yearly`. You can't change the Product ID later.
  2. Duration: **1 Year**.
  3. **Subscription Prices:** choose USD **$4.99** and let Apple set the other countries automatically.
  4. **Introductory Offer:** click **+**, then set:
     - Countries: all
     - Start date: today, with no end date
     - Type: **Free**
     - Duration: **1 Week**
  5. **Localization (English U.S.):** display name "Premium (Yearly)", description "Unlock all 12 themes for the app and widget."
  6. **Review Information:** upload a screenshot of the paywall from the iPhone. Notes: "Unlocks all themes. Core to-do features are free."
  7. Family Sharing: optional. You can turn it on, but you can't turn it off afterwards.

### In-app purchase: premium_lifetime

Go to **Monetization** → **In-App Purchases** → **+**.

- [ ] **Create the product**
  1. Type: **Non-Consumable**. Reference name "Premium Lifetime". Product ID `premium_lifetime`.
  2. **Price:** USD **$14.99**.
  3. **Localization:** display name "Premium (Lifetime)", description "Unlock all 12 themes forever with a one-time purchase."
  4. **Review Information:** the same paywall screenshot and the same note.

### First submission

- [ ] Apple reviews the **first** in-app purchases together with the first app version.
  1. On the version page (**1.0 Prepare for Submission**), scroll to **In-App Purchases and Subscriptions**.
  2. Click **+** and select both products before you submit.
  3. Later price or product changes don't need a new app version. See section 4.

### Keys and notifications for RevenueCat

- [ ] **In-App Purchase key**
  1. Go to **Users and Access** → **Integrations** → **In-App Purchase** and generate a key named "RevenueCat".
  2. Download the `.p8` file. You can only download it once.
  3. Note the **Key ID** and the **Issuer ID**, which is shown at the top of the page.
- [ ] **Server notifications**
  1. Get the URL from RevenueCat in section 3.
  2. Go to your app → **App Information** → **App Store Server Notifications**.
  3. Paste the URL for both **Production** and **Sandbox**, and choose **Version 2**.

### App Store listing

Copy the text from `docs/appstore/metadata.md`.

- [ ] Fill in the name, subtitle, promotional text, description, keywords, support URL, and the privacy policy URL `https://shavastudios.ai/todo1/privacy`.
- [ ] Add a **Terms of Use (EULA)** link.
  - Leave the License Agreement as Apple's **standard EULA**. That is the default under **App Information**.
  - The description in `metadata.md` already ends with the Terms of Use link. Guideline 3.1.2 requires a working link to the Terms of Use for any app that sells subscriptions.
- [ ] Add screenshots.
  - The **6.9-inch** iPhone set is required. Take them in the **iPhone 17 Pro Max** simulator, or use 1320 × 2868 px images.
  - Suggested set:
    1. The widget on a home screen
    2. The theme gallery
    3. Three themed widgets side by side
    4. Quick add
    5. The task list
    6. The paywall
  - Use only your own content. Don't show any other app's name or icon.
- [ ] **App Review Information:** fill in the contact name, phone and email, set **Sign-in required** to **No**, and paste the review notes from `docs/appstore/metadata.md`.

## 3. RevenueCat

- [ ] **Projects** → **+ Create project** named "Todo1".
- [ ] **Add the App Store app**
  1. In the project, add an **App Store** app with the Bundle ID `ai.shavastudios.todo1`.
  2. Upload the **In-App Purchase Key** (`.p8`), with its Key ID and Issuer ID, from section 2.
  3. Copy the **Apple Server to Server notification URL** that RevenueCat shows. Paste it into App Store Connect as described in section 2.
  4. If you are testing purchases in Xcode with the local `.storekit` file, upload the StoreKit certificate the Mac person sends you (MAC_SETUP, step 7) in this app's settings.
- [ ] **Products:** add or import `premium_yearly` and `premium_lifetime`.
- [ ] **Entitlement**
  1. Go to **Entitlements** → **+**, enter the identifier `premium` (lowercase, exactly) and the description "Premium themes".
  2. Attach **both** products.
- [ ] **Offering**
  1. Go to **Offerings** → **+**, enter the identifier `default` and the description "Launch".
  2. Add two packages:
     - **Annual** (`$rc_annual`) → `premium_yearly`
     - **Lifetime** (`$rc_lifetime`) → `premium_lifetime`
  3. Mark the offering as **Current** (the default offering).
- [ ] **Offering metadata.** Open the `default` offering → **Metadata** and paste:
  ```json
  {"free_theme_count":3,"theme_order":[]}
  ```
  - An empty `theme_order` means the app's bundled order:
    `paper, midnight, mono-mint, terminal, brutalist, receipt, swiss, blueprint, pocket-8bit, neon, zen, sticky-note`
  - The first `free_theme_count` themes in that order are free.
- [ ] **Paywall**
  1. Go to **Paywalls** → create a paywall for the `default` offering and pick a template.
  2. Make sure the paywall shows:
     - the price and period of each package
     - the trial wording ("1 week free, then $4.99/year")
     - that the subscription renews automatically
     - a **Restore Purchases** button
     - links to the **Terms of Use** (`https://shavastudios.ai/todo1/terms`) and the **Privacy Policy** (`https://shavastudios.ai/todo1/privacy`)
  3. **Publish** it.
- [ ] **API key**
  1. Go to **Project settings** → **API keys** and copy the **Apple App Store public SDK key**. It starts with `appl_`.
  2. Give it to the Mac person for `Config/Local.xcconfig` (`REVENUECAT_API_KEY = appl_…`).
  3. Don't commit it to the repository.

## 4. Changing prices later (no app update needed)

| You want to… | Do this |
|---|---|
| 1. Keep the same product with a new price | App Store Connect → the product → **Subscription Prices** (or **Price Schedule** for lifetime) → plan a price change. Existing subscribers can keep their old price. |
| 2. Use a different product or trial (for example monthly, or a 2-week trial) | Create the new product in App Store Connect. After your first in-app purchase is approved, new ones can go to review **on their own**, without a new app version. Then add the product to RevenueCat and point the offering's package at it. |
| 3. Change the paywall design, wording or layout | Edit it in RevenueCat's paywall editor and publish. |
| 4. A/B test prices | Use RevenueCat **Experiments**. Create a second offering with other products, and start an experiment between the `default` offering and it. |
| 5. Change how many themes are free, or which ones | Edit the `default` offering's **Metadata**. For example, `{"free_theme_count":4,"theme_order":["paper","terminal","midnight","mono-mint"]}` makes those four free and moves them first. Theme IDs that aren't listed keep their bundled order after them, and unknown IDs are ignored. Users get the change the next time they open the app. |

## 5. App Privacy answers

Go to App Store Connect → your app → **App Privacy** → **Get Started**.

- [ ] **Do you or your third-party partners collect data from this app?** Answer **Yes**. RevenueCat processes purchase history.
- [ ] Data type **Purchases → Purchase History**:
  - Used for: **App Functionality**
  - Linked to the user's identity: **No**
  - Used for tracking: **No**
- [ ] Before you submit, read RevenueCat's current "Apple App Privacy" guidance in their docs. It may also ask you to declare **Identifiers → User ID** for its anonymous app user ID, with the same answers: App Functionality, not linked, not tracking. Follow whatever it currently says.
- [ ] Don't declare the user's tasks. They stay on the device and in the user's **own private iCloud database**, which neither you nor anyone else can read. That isn't "collected" in Apple's terms.
- [ ] Everything else is **not collected**: no contact info, no location, no usage data, no diagnostics, no ads. The app doesn't use App Tracking Transparency because it doesn't track.

## 6. Privacy Policy and Terms of Use pages

The app links to `AppConstants.privacyPolicyURL` and `AppConstants.termsURL`, which are set in `Packages/TodoCore/Sources/TodoKit/AppConstants.swift`:

- `https://shavastudios.ai/todo1/privacy`
- `https://shavastudios.ai/todo1/terms`

- [ ] Before you submit, publish `site/privacy.html` and `site/terms.html` at **exactly** those URLs. For example:
  - upload them as `todo1/privacy/index.html` and `todo1/terms/index.html` on the shavastudios.ai web host
  - or use a host such as Netlify or Cloudflare Pages, which serves `privacy.html` at `/privacy`
- [ ] Open both URLs on a phone and check that they load over **https**.
- [ ] If you'd rather host them somewhere else, such as GitHub Pages:
  1. Change the two URLs in `AppConstants.swift` **before** the build you submit.
  2. Use the same URLs in App Store Connect and in the RevenueCat paywall.
- [ ] **Support URL.** App Store Connect also needs one. Make a simple page, for example `https://shavastudios.ai/todo1/support`, that says "Questions or problems? Email singh.tejash@shavastudios.ai".
- [ ] Read both pages once. They name **Shava Studios** as the maker and say Terms are governed by "the laws of the country where Shava Studios is established". If you enrol as an individual, or want to name a specific country, edit those lines. If the public app name isn't "Todo1", replace "Todo1" in both pages too.
- [ ] If you changed the URLs, also update the Privacy Policy link inside `site/terms.html` (section 6).

## 7. Review notes

Paste the **Review notes** section of `docs/appstore/metadata.md` into App Store Connect → the version → **App Review Information** → **Notes**. It explains three things:

- how to add the widget
- that the core to-do features are free and Premium only unlocks themes
- how to test the purchase in the sandbox

## 8. TestFlight test pass

Do this with a TestFlight build on a real iPhone. Purchases in TestFlight are free and use the sandbox. Subscriptions renew much faster than in real life.

### Review Focus items

- [ ] **1. Overdue repeating task**
  1. Create a task that repeats **daily** at **09:00**, with a due date **5 days ago**.
  2. Complete it.
  3. It should stay open, with its due date moved to the **next** 09:00 after now: today if it is before 09:00, otherwise tomorrow. It should not move to "4 days ago".
- [ ] **2. Month-end and leap-day repeats**
  1. Create a **monthly** task due on **31 January** next year. Complete it. It should move to **28 February** (29 in a leap year). Complete it again. It should move to **31 March**, not 28 March.
  2. Create a **yearly** task due on **29 February 2028**. Complete it. It should move to **28 February 2029**.
- [ ] **3. Garbage remote config**
  1. In RevenueCat, set the `default` offering metadata to each of these in turn. After each change, force-quit and reopen the app, then check the theme gallery.
     - `{"free_theme_count":-1}`: at least Paper is free, and the app doesn't crash.
     - `{"free_theme_count":"lots"}`: falls back to 3 free themes.
     - `{"free_theme_count":99}`: all 12 themes are free.
     - `{"free_theme_count":3,"theme_order":["nope","neon"]}`: Neon comes first and is free, and "nope" is ignored.
  2. Afterwards, restore `{"free_theme_count":3,"theme_order":[]}`.
- [ ] **4. Fresh install with no shared data**
  1. Delete the app.
  2. Reinstall it from TestFlight, but **don't open it**.
  3. Add the widget. It should show the Paper theme with an "All clear" empty state. It should not be blank and should not crash.
  4. Open the app. The widget should update.
- [ ] **5. Blank and very long titles**
  - In quick add, type only spaces and press Return. Nothing should be added.
  - Paste a title that is over 600 characters long. It should be saved with surrounding spaces trimmed and cut to 500 characters.
  - Say to Siri "Add a task in <name>", then answer with silence or just "um". No blank task should be created.

### Widget

- [ ] Small, medium and large sizes. Ticking a checkbox works, "+" opens quick add, tapping a row opens the task, and "+N more" appears when there are more tasks.
- [ ] Light mode, dark mode and **tinted** home screen mode. On iOS 18 or later, long-press the home screen → **Edit** → **Customize** → **Tinted**. Also try **Clear** mode on iOS 26. Every theme should stay readable.
- [ ] Choose a premium theme for the widget without Premium. The widget should show Paper with a "Theme locked" footer, and tapping the footer opens the theme gallery.

### Purchases (sandbox)

- [ ] Start the **yearly free trial**. The paywall should show "1 week free" and the price after it. All themes should unlock in the app and in the widget's theme list.
- [ ] Let the trial or subscription expire. Sandbox renewals are fast, or you can cancel in Settings → your name → **Subscriptions**. Themes should lock again, widgets should fall back to Paper, and your chosen theme should come back after you resubscribe.
- [ ] **Lifetime** purchase. Then delete and reinstall the app and tap **Restore Purchases**. Premium should come back.
- [ ] **Manage Subscription** in the app's Settings opens Apple's subscription sheet.

### Everything else

- [ ] **iCloud sync:** use two devices on the same Apple ID. Add, complete and delete tasks on each device, including from the widget. Changes should appear on the other device within a minute or two of opening the app.
- [ ] **Reminders:** add a task with a time 2 minutes from now. The permission prompt should appear on that first save, and the notification should arrive. Tapping the notification should open that task.
- [ ] **Siri and Shortcuts:** "Add a task in <name>" works. The action also appears in the Shortcuts app.
- [ ] **Offline:** turn on Airplane Mode and launch the app. It should work in free mode or with cached Premium, and should not crash.
- [ ] **Links:** the Privacy Policy and Terms of Use links in Settings and on the paywall open the live pages.

## 9. Submit

- [ ] Build version 1.0.0 has been uploaded (MAC_SETUP, step 8) and has passed the TestFlight pass above.
- [ ] On the version page, select the build and both in-app purchases. Then click **Add for Review** → **Submit**.
- [ ] If Apple rejects the app, read the message in **Resolution Center**, fix the problem and resubmit. Rejections for metadata or missing links are common and quick to fix.
