import Foundation

/// Shared between the app, its Shortcuts action and the widget extension.
let appGroupID = "group.io.github.ayush3401.lifedots"

enum Theme: String, Codable, CaseIterable, Identifiable {
    case dark, light
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct LifeSettings: Codable, Equatable {
    var birthDate: Date?
    var lifeExpectancyYears: Int = 80
    var theme: Theme = .dark
    var showCaption: Bool = true

    func stats(now: Date = Date()) -> LifeStats? {
        guard let birthDate else { return nil }
        return LifeCalculator.stats(birthDate: birthDate, lifeExpectancyYears: lifeExpectancyYears, now: now)
    }

    /// Sample data for widget previews before the user has set a birthday.
    static var preview: LifeSettings {
        LifeSettings(birthDate: Calendar.current.date(byAdding: .year, value: -30, to: Date()))
    }
}

/// The screen the wallpaper is drawn for. The app records it on launch because
/// the Shortcuts action runs in the background without a screen to ask.
struct ScreenInfo: Codable, Equatable {
    var pixelWidth: Int
    var pixelHeight: Int
    var scale: Double

    /// iPhone 15 / 16 Pro, used until the app has been opened once.
    static let fallback = ScreenInfo(pixelWidth: 1179, pixelHeight: 2556, scale: 3)
}

/// Settings live in the App Group's UserDefaults so the widget can read them.
enum SharedStore {
    private static var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    static func loadSettings() -> LifeSettings { decode(LifeSettings.self, key: "settings") ?? LifeSettings() }
    static func save(_ settings: LifeSettings) { encode(settings, key: "settings") }

    static func loadScreen() -> ScreenInfo { decode(ScreenInfo.self, key: "screen") ?? .fallback }
    static func save(_ screen: ScreenInfo) { encode(screen, key: "screen") }

    private static func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
}
