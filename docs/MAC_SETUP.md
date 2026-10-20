# Mac setup: build, run and upload Todo1

This guide is for someone with a Mac who has not built an iOS app before. Do the steps in order. Each one ends with how to tell it worked.

You will need:

- A Mac on a recent macOS. Xcode 26 needs macOS Sequoia 15.6 or newer, and the App Store will tell you if your Mac is too old.
- About 40 GB of free disk space for Xcode and the iOS simulator.
- An iPhone on iOS 17 or newer, and a USB cable. You only need this for steps 6 and onward, but the widget and iCloud are best tested on a real phone.
- Access to the app owner's Apple Developer account (see step 0).
- About 2 hours the first time. Most of that is waiting for downloads.

> **Important:** this code was written on a Linux machine where it could not be compiled. Expect the first build to show some compile errors. That is normal. Step 3b explains how to capture the errors and send them back so they can be fixed. Don't try to fix the Swift code yourself unless you want to.

---

## Step 0: Get access to the owner's Apple Developer account

The app is signed with the **owner's** Apple Developer team, not yours. Pick one of these:

- **Option A (recommended): the owner invites you.**
  1. The owner goes to [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → **+**.
  2. They enter your Apple ID email and choose the role **Admin**. Admin lets Xcode create the App Group and iCloud container for you, and the owner can lower your role later.
  3. You accept the email invitation.
- **Option B: the owner signs in on your Mac.** In step 4, they add their own Apple ID in Xcode. They will need to approve a two-factor code on their own device.

You also need the owner's **Team ID**:

1. Go to [developer.apple.com/account](https://developer.apple.com/account).
2. Open **Membership details**.
3. The Team ID is 10 letters and digits, like `ABCDE12345`.

Ask the owner for the **RevenueCat public Apple API key** too. It starts with `appl_`. Without it, the app still runs, but it stays in free mode and the paywall says "Purchases unavailable right now".

---

## Step 1: Install Xcode and XcodeGen

1. Open the **App Store** on the Mac, search for **Xcode**, and install it. It is several GB, so expect a wait.
2. Open Xcode once. Accept the licence. When it asks which platforms to install, make sure **iOS** is ticked. If you missed it, go to Xcode → **Settings** → **Components** and install the iOS platform.
3. Open the **Terminal** app (press ⌘Space and type "Terminal") and run:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app
   xcodebuild -version
   ```
   You should see `Xcode 26.x` or newer.
4. Install Homebrew, a package manager, if you don't already have it. Paste the install command from [brew.sh](https://brew.sh) into Terminal. When it finishes, it prints two "Next steps" commands that start with `echo` and `eval`. Run them.
5. Install XcodeGen, which turns `project.yml` into an Xcode project:
   ```bash
   brew install xcodegen
   xcodegen --version
   ```
   You should see a version number. If you get `command not found`, run `eval "$(/opt/homebrew/bin/brew shellenv)"` and try again.

---

## Step 2: Get the code and add your local settings

1. Get the project folder from the owner. They can either:
   - invite you to the private GitHub repository, then you run:
     ```bash
     cd ~/Desktop
     git clone https://github.com/<owner>/todo1.git
     cd todo1
     ```
   - or send you a zip. Unzip it on the Desktop, then run `cd ~/Desktop/todo1` in Terminal.
2. Create the file `Config/Local.xcconfig` with the Team ID and RevenueCat key from step 0. Replace the example values below with the real ones:
   ```bash
   cat > Config/Local.xcconfig <<'EOF'
   DEVELOPMENT_TEAM = ABCDE12345
   REVENUECAT_API_KEY = appl_yourKeyFromRevenueCat
   EOF
   ```
   - This file is listed in `.gitignore`, so the key is never committed.
   - If you don't have the RevenueCat key yet, leave that line out. The app runs in free mode.

**Check:** run `cat Config/Local.xcconfig`. It should show your two lines.

---

## Step 3: Generate and open the Xcode project

1. Run this from the `todo1` folder:
   ```bash
   xcodegen generate
   open Todo1.xcodeproj
   ```
2. Xcode opens and downloads the Swift packages, including RevenueCat. The status bar at the top shows progress, and it takes a minute or two.
3. Run `xcodegen generate` again whenever you pull new code or `project.yml` changes.

> Don't change project settings in Xcode's UI expecting them to stick. `xcodegen generate` rebuilds `Todo1.xcodeproj` from `project.yml` and throws those changes away. Your team ID is safe because it lives in `Local.xcconfig`. If a setting needs a permanent change, tell the owner so it goes into `project.yml`.

### 3a: First build on the simulator

1. In the toolbar at the top of Xcode, check that the scheme is **Todo1**. Next to it, pick a simulator such as **iPhone 17**.
2. Press **⌘B** (Product → Build).

If it succeeds, you will see "Build Succeeded". Go to step 4.

### 3b: If the build fails, send the errors back

1. Run this in Terminal from the `todo1` folder. It builds without signing and saves the full log:
   ```bash
   xcodebuild -project Todo1.xcodeproj -scheme Todo1 \
     -destination 'generic/platform=iOS Simulator' \
     CODE_SIGNING_ALLOWED=NO build 2>&1 | tee build.log
   grep -E "error:" build.log | sort -u > errors.txt
   wc -l errors.txt
   ```
2. Send **both `errors.txt` and `build.log`** to the owner. Once the fixes come back, pull or unzip the new code, run `xcodegen generate`, and build again.

> Tip: if [Claude Code](https://claude.com/claude-code) is installed on the Mac, open it in the `todo1` folder and ask it to "build with xcodebuild and fix the compile errors". It can run the build-and-fix loop itself.

---

## Step 4: Signing and capabilities

1. Add the Apple ID to Xcode:
   1. Go to Xcode → **Settings** → **Accounts**.
   2. Click **+**, choose **Apple ID**, and sign in. Use your own Apple ID for option A, or the owner's for option B.
   3. The owner's team should appear in the list. For option A, that only happens after you accept the invitation.
2. In the left sidebar, click the blue **Todo1** project icon. Then check each target in turn under **TARGETS**.
3. Target **Todo1**, **Signing & Capabilities** tab:
   1. Tick **Automatically manage signing**.
   2. Set **Team** to the owner's team.
   3. Check that **Bundle Identifier** is `ai.shavastudios.todo1`.
   4. Check these capabilities. They come from the project files, so they should already be there:
      - **App Groups:** `group.ai.shavastudios.todo1` is ticked. If it shows in red, click the small refresh arrow under the list, or click **+** and add exactly `group.ai.shavastudios.todo1`.
      - **iCloud:** **CloudKit** is ticked, and the container `iCloud.ai.shavastudios.todo1` is ticked. If the container is red or missing, click **+** under Containers and add exactly `iCloud.ai.shavastudios.todo1`.
      - **Push Notifications** is listed. CloudKit sync needs it.
      - **Background Modes:** **Remote notifications** is ticked.
4. Target **Todo1Widget**, **Signing & Capabilities** tab:
   1. Tick **Automatically manage signing**.
   2. Set **Team** to the same team.
   3. Check that **Bundle Identifier** is `ai.shavastudios.todo1.widget`.
   4. **App Groups:** `group.ai.shavastudios.todo1` is ticked.

**Check:** there are no red error messages in either target's Signing section. If there are, see [Troubleshooting](#troubleshooting).

---

## Step 5: Run the unit tests

Run this in Terminal from the `todo1` folder:

```bash
cd Packages/TodoCore && swift test; cd ../..
```

At the end, you should see a line like `Test run with N tests passed`. If anything fails, send the full output to the owner.

---

## Step 6: Run on the iPhone and try the main features

### Prepare the phone

1. Connect the iPhone to the Mac with the cable. Unlock it and tap **Trust** when asked.
2. On the iPhone, open Settings → **Privacy & Security** → **Developer Mode**, turn it on, and let the phone restart. This option only appears after the phone has been connected to Xcode once.
3. Make sure the iPhone is signed in to iCloud and that iCloud Drive is on. Sync needs both.

### Run the app

1. In Xcode's toolbar, choose your iPhone as the destination instead of a simulator.
2. Press **⌘R** (Product → Run).
3. The first time, Xcode may take a few minutes to "prepare the device". If the iPhone says "Untrusted Developer", go to Settings → **General** → **VPN & Device Management**, tap the developer, and tap **Trust**.

### Try these on the phone

1. **Onboarding:** swipe through the three pages, pick a theme, and tap **Get started**.
2. **Add tasks in the app:**
   1. Tap **+**.
   2. Type a title and press Return. The sheet should stay open with the field cleared.
   3. Add two or three tasks, including one for "Today".
   4. Swipe down to close.
3. **Add the widget:**
   1. Go to the Home Screen. Long-press an empty area until the icons jiggle.
   2. Tap **Edit** (top left), then **Add Widget**.
   3. Search for **Todo1**, choose the **Medium** size, and tap **Add Widget**. Then tap **Done**.
4. **Tick a task in the widget:** tap a checkbox on the widget. The task should be marked done without the app opening. Open the app and check that it shows as completed.
5. **Tap "+" in the widget:** the app should open straight to quick add with the keyboard up.
6. **Change the widget's list and theme:** long-press the widget → **Edit Widget**. Choose a list and a theme. Locked themes have a 🔒, and if you pick one the widget shows Paper with a "Theme locked" footer.
7. **Reminder:**
   1. Add a task with a time 2 minutes from now.
   2. When asked for notification permission, allow it.
   3. Lock the phone and wait. A notification should appear.
8. **Siri:** say "Hey Siri, add a task in Todo1", then say a title when Siri asks. You can also open the **Shortcuts** app, where Todo1's "Add a task" action is listed under App Shortcuts.
9. **iCloud:** open the app's **Settings** screen. It should say "Syncing with iCloud".

Note anything that looks wrong, ideally with a screenshot, and send it to the owner.

---

## Step 7: Test purchases with the local StoreKit file (no real money)

The **Todo1** scheme uses `App/Resources/Todo1.storekit`. When you run from Xcode, purchases use these fake products instead of the real App Store:

- `premium_yearly`: $4.99 a year with a 1-week free trial
- `premium_lifetime`: $14.99

The paywall itself is drawn by RevenueCat, so you need:

- the RevenueCat key in `Local.xcconfig`
- the owner's RevenueCat setup done (LAUNCH_CHECKLIST, section 3)
- RevenueCat's servers set up to trust local StoreKit purchases:
  1. In Xcode, open `Todo1.storekit` from the left sidebar.
  2. Choose **Editor** → **Save Public Certificate** and save the file.
  3. Send the file to the owner. They upload it in RevenueCat, under the app's settings, in the StoreKit configuration certificate field. RevenueCat's docs page "Testing with StoreKit Configuration Files" shows where.

### Try these purchase tests

1. Run the app, go to **Settings** → **Upgrade**, and buy the yearly plan. It should show the 1-week free trial. Confirm the fake payment sheet. Every theme should unlock in the gallery and in the widget's theme list.
2. **Make the subscription expire:**
   1. Go to **Debug** → **StoreKit** → **Manage Transactions…**.
   2. Select the purchase and click **Expire** or **Refund**. In some Xcode versions this is a right-click menu.
   3. Go back to the app. The themes should lock again, and a widget using a premium theme should fall back to Paper.
3. **Speed up renewals:** with `Todo1.storekit` open, use the **Editor** menu → **Subscription Renewal Rate**. Some Xcode versions call it **Time Rate**.
4. **Restore Purchases:** delete the transactions in Manage Transactions, buy the lifetime product, delete and reinstall the app, then tap **Settings** → **Restore Purchases**.

### Test with the real sandbox (later)

To test against Apple's real test servers instead:

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme…** → **Run** → **Options**.
2. Set **StoreKit Configuration** to **None**.
3. Run on the iPhone.
4. Sign in to a Sandbox Apple Account under iPhone Settings → **Developer** → **Sandbox Apple Account**, or under Settings → **App Store** on some iOS versions. The owner creates Sandbox accounts in App Store Connect → **Users and Access** → **Sandbox**.

`xcodegen generate` resets the scheme to the local StoreKit file. That is intended.

---

## Step 8: Upload to App Store Connect (TestFlight)

Before your first upload, the owner must have created the app record in App Store Connect (LAUNCH_CHECKLIST, section 2).

1. Check that `Config/Local.xcconfig` contains the real `REVENUECAT_API_KEY`. The key is baked into the build.
2. In Xcode's toolbar, set the destination to **Any iOS Device (arm64)**. Archive is greyed out while a simulator is selected.
3. Choose **Product** → **Archive**. When it finishes, the **Organizer** window opens with the new archive selected.
4. Click **Distribute App** → **App Store Connect** → **Distribute**. On older Xcode versions, choose **Upload** and keep the default options.
   - Leave **Manage Version and Build Number** ticked if it is offered. That way, every upload gets a new build number automatically.
   - Without that option, raise `CURRENT_PROJECT_VERSION` in `project.yml` by 1 before each upload, then run `xcodegen generate`. Apple rejects an upload whose build number was already used.
5. Wait for "Upload Successful".
6. Within 5 to 30 minutes, the build appears in App Store Connect → your app → **TestFlight**. The app declares that it uses no special encryption, so no export-compliance question should block it.
7. In TestFlight, add yourself and the owner as **Internal Testers**. Install the **TestFlight** app on the iPhone to get the build.

---

## Troubleshooting

| What you see | What it usually means and what to do |
|---|---|
| A signing error that mentions `com.apple.security.application-groups`, `group.ai.shavastudios.todo1`, `iCloud.ai.shavastudios.todo1` or "Provisioning profile doesn't include…" | The App Group or iCloud container hasn't been created in the developer account yet. 1. Make sure **Automatically manage signing** is ticked and the team is set for **both** targets. 2. Under the App Groups or iCloud capability, click the refresh arrow, or click **+** and add the exact identifier. 3. If it still fails, the owner creates them by hand at developer.apple.com → **Certificates, Identifiers & Profiles** → **Identifiers** (LAUNCH_CHECKLIST, section 1). Then click **Try Again** in Xcode. Creating identifiers needs the **Admin** or **Account Holder** role. |
| "No Account for Team" or "No signing certificate" | Add the Apple ID under Xcode → Settings → **Accounts**. Select it, click **Manage Certificates**, then **+** → **Apple Development**. |
| "The bundle identifier / container identifier is not available" | Someone else already owns that identifier. Tell the owner. They choose a new one and update `project.yml`, the entitlements files and `AppConstants.swift`. |
| `xcodegen: command not found` | Run `eval "$(/opt/homebrew/bin/brew shellenv)"`, then try again. |
| Package resolution fails ("Missing package product RevenueCat") | Use File → **Packages** → **Reset Package Caches**, then **Resolve Package Versions**. Check the Mac's internet connection. |
| `swift test` says "no such module" or uses the wrong Swift | Run `sudo xcode-select -s /Applications/Xcode.app` and try again. |
| The widget doesn't appear in the widget gallery | Run the app from Xcode once and open it on the phone. Then restart the iPhone. |
| The widget shows Paper with "Theme locked" | This is expected for premium themes without Premium. |
| Settings shows "iCloud unavailable" | Sign the iPhone in to iCloud and turn on iCloud Drive. In a simulator, sign in under the simulator's Settings app. |
| The paywall says "Purchases unavailable right now" | `REVENUECAT_API_KEY` is missing from `Config/Local.xcconfig`, or still says `REPLACE_ME`. Add the key, then build again with **⌘B**. |
| "Developer Mode disabled" or the iPhone isn't in the destination list | Do step 6 "Prepare the phone". Unlock the phone and keep it unlocked while Xcode prepares it. |
| Compile errors in Swift files | Follow step 3b and send `errors.txt` and `build.log` to the owner. |
