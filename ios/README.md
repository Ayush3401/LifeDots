# LifeDots for iOS

iOS doesn't let apps change the wallpaper. So LifeDots gives you two things:

- **A Shortcuts action, "Generate LifeDots Wallpaper"**, which draws today's grid at your iPhone's exact resolution. A daily Shortcuts automation passes it to the built-in **Set Wallpaper Photo** action, so your Lock Screen updates by itself. The app walks you through setting it up.
- **Widgets.** Small, medium and large Home Screen widgets, plus circular, rectangular and inline Lock Screen widgets. They refresh just after midnight and need no setup.

The wallpaper leaves room at the top for the Lock Screen clock and at the bottom for the flashlight and camera buttons.

Requires iOS 17 or later.

## Build

You need the full **Xcode** app (from the App Store). The Command Line Tools alone can't build iOS apps.

```bash
cd ios
./generate.sh      # creates LifeDots.xcodeproj and opens it
```

`generate.sh` uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to create the Xcode project from `project.yml`. If XcodeGen isn't installed, the script downloads it into `ios/.tools/`, so you don't need Homebrew or admin rights. Run the script again whenever you add or remove files.

In Xcode:
1. Select the **LifeDots** project, then for **both** targets (`LifeDots` and `LifeDotsWidget`) open **Signing & Capabilities** and choose your Team. A free Apple ID works for running on your own phone.
2. Plug in your iPhone, select it as the run destination and press **Run ▶**. The first time, approve the developer under **Settings → General → VPN & Device Management** on the phone.

Apps installed with a free Apple ID stop working after 7 days until you run them from Xcode again. A paid Apple Developer account ($99/year) removes that limit and lets you share the app through TestFlight or the App Store.

The app and its widget share settings through an App Group (`group.io.github.ayush3401.lifedots`). If Xcode reports a signing error about App Groups, change that ID in `project.yml` to one unique to you and run `./generate.sh` again.

## Code

| File | Role |
|---|---|
| `Shared/LifeCalculator.swift` | Weeks lived and weeks left, identical to the macOS app |
| `Shared/DotsRenderer.swift` | Draws the grid (layout with the largest dots, full rows preferred) for the wallpaper, preview and widgets |
| `Shared/Model.swift` | Settings, stored in the App Group so the widget can read them |
| `LifeDots/WallpaperIntent.swift` | The Shortcuts action |
| `LifeDots/ContentView.swift` | Settings, Lock Screen preview, Shortcuts setup guide, Save to Photos |
| `Widget/LifeDotsWidget.swift` | Home Screen and Lock Screen widgets |
