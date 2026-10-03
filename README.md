# LifeDots

Your wallpaper as a grid of dots, one for every week of your life. Weeks you've lived are filled in, the current week is orange, and the weeks you have left are dimmed. It updates by itself.

| macOS | Android |
|---|---|
| ![macOS](docs/macos-preview.png) | <img src="docs/android-preview.png" width="220" alt="Android"> |

## Download

| | |
|---|---|
| **Android** 8.1+ | [**LifeDots-android.apk**](https://github.com/Ayush3401/LifeDots/releases/latest/download/LifeDots-android.apk). Open the link on your phone and install it. If asked, allow your browser to install apps. |
| **macOS** 13+ | [**LifeDots-macOS.zip**](https://github.com/Ayush3401/LifeDots/releases/latest/download/LifeDots-macOS.zip). Unzip it, drag LifeDots to Applications and open it. If macOS blocks it, go to System Settings → Privacy & Security → **Open Anyway**. |

All versions are on the [Releases page](https://github.com/Ayush3401/LifeDots/releases).

## Apps

| Platform | How it works | Source |
|---|---|---|
| **macOS** 13+ | Menu-bar app that sets the desktop picture on every display | [build from source](macos/README.md) |
| **Android** 8.1+ | Live wallpaper that redraws itself each time you look at it | [build from source](android/README.md) |

Both apps count weeks the same way. Each year has 52 weeks, counted from your birthday, so every year starts a new row and leap years don't shift the grid.

## Releasing (for maintainers)

Pushing a tag builds both apps on GitHub and publishes them as a release:

```bash
git tag v1.0 && git push origin v1.0
```

The Android build is signed with a release key stored in the repo's Actions secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).

## License

[MIT](LICENSE)
