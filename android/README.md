# LifeDots for Android

<img src="../docs/android-preview.png" width="260" alt="LifeDots on a phone">

LifeDots runs as a **live wallpaper**: the app draws the wallpaper itself and redraws it each time the screen turns on or you return to the home screen. It's always up to date, with no background jobs and no saved images. The app needs no permissions and uses no libraries besides the Android SDK.

Requires Android 8.1 or later.

## Build

1. Install [Android Studio](https://developer.android.com/studio). Use a recent version, because the project uses Android Gradle Plugin 9.4.
2. Choose **File → Open** and select this `android/` folder, not the repo root. Wait for the Gradle sync to finish.
3. To run on your phone, turn on USB debugging, plug in the phone and click **Run ▶**.
4. To get an APK you can share, choose **Build → Generate App Bundles or APKs → Generate APKs**. The file is saved as `app/build/outputs/apk/debug/app-debug.apk`.

For a smaller release APK, switch the build variant to **release** (View → Tool Windows → Build Variants) and build again. To keep testing simple, the release build is signed with your local debug key. Use a proper keystore before publishing to Google Play.

## Use

1. Open LifeDots and set your date of birth and life expectancy.
2. Tap **Set as wallpaper**. Choose "Home and lock screen" if your phone asks.

Changes you make in the app reach the wallpaper immediately. Some phones, notably Samsung, don't allow live wallpapers on the lock screen, so the dots appear on the home screen only.

## Code

| File | Role |
|---|---|
| `LifeCalculator.kt` | Weeks lived and left, using the same model as the macOS app |
| `DotsRenderer.kt` | Draws the grid. Picks the layout with the largest dots and prefers full rows (52 = one year per row on most phones) |
| `LifeDotsWallpaperService.kt` | The live wallpaper. Redraws when visible and stays clear of the status and navigation bars |
| `MainActivity.kt`, `PreviewView.kt` | Settings screen with a live preview |
| `Prefs.kt` | Saved settings, shared with the wallpaper through a change listener |
