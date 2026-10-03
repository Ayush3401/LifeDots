import AppIntents
import UIKit
import UniformTypeIdentifiers

/// The Shortcuts action. Apps can't set the wallpaper on iOS, so this returns
/// today's image and Shortcuts' own "Set Wallpaper Photo" action applies it.
struct GenerateWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate LifeDots Wallpaper"
    static let description = IntentDescription(
        "Creates today's LifeDots wallpaper at your iPhone's screen size. Pass it to Set Wallpaper Photo.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let settings = SharedStore.loadSettings()
        guard settings.birthDate != nil else { throw LifeDotsIntentError.noBirthday }

        let image = DotsRenderer.wallpaper(settings: settings, screen: SharedStore.loadScreen())
        guard let data = image.pngData() else { throw LifeDotsIntentError.renderFailed }
        return .result(value: IntentFile(data: data, filename: "LifeDots.png", type: .png))
    }
}

enum LifeDotsIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noBirthday
    case renderFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noBirthday: return "Open LifeDots and set your birthday first."
        case .renderFailed: return "LifeDots couldn't create the wallpaper image."
        }
    }
}

/// Makes the action show up in Shortcuts without any setup.
struct LifeDotsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GenerateWallpaperIntent(),
            phrases: ["Generate \(.applicationName) wallpaper"],
            shortTitle: "LifeDots Wallpaper",
            systemImageName: "circle.grid.3x3.fill"
        )
    }
}
