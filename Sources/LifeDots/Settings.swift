import Foundation
import Combine

enum Theme: String, CaseIterable, Identifiable {
    case dark, light
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// User preferences, persisted in UserDefaults. Every change is observable so
/// the app can redraw the wallpaper as soon as something is edited.
final class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults = UserDefaults.standard
    private enum Key {
        static let birthDate = "birthDate"
        static let years = "lifeExpectancyYears"
        static let theme = "theme"
        static let showCaption = "showCaption"
    }

    @Published var birthDate: Date? {
        didSet { defaults.set(birthDate, forKey: Key.birthDate) }
    }
    @Published var lifeExpectancyYears: Int {
        didSet { defaults.set(lifeExpectancyYears, forKey: Key.years) }
    }
    @Published var theme: Theme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }
    @Published var showCaption: Bool {
        didSet { defaults.set(showCaption, forKey: Key.showCaption) }
    }

    private init() {
        birthDate = defaults.object(forKey: Key.birthDate) as? Date
        let years = defaults.integer(forKey: Key.years)
        lifeExpectancyYears = (1...120).contains(years) ? years : 80
        theme = Theme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .dark
        showCaption = defaults.object(forKey: Key.showCaption) as? Bool ?? true
    }

    func currentStats(now: Date = Date()) -> LifeStats? {
        guard let birthDate else { return nil }
        return LifeCalculator.stats(birthDate: birthDate,
                                    lifeExpectancyYears: lifeExpectancyYears,
                                    now: now)
    }
}
