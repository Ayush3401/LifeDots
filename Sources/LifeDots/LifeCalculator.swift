import Foundation

/// Life measured on the classic "life in weeks" grid: every year of life is
/// exactly 52 dots, and week N of a year starts N*7 days after that year's
/// birthday. Anchoring to birthdays keeps a year's row aligned no matter how
/// leap years fall, so the grid stays stable when you look at it.
struct LifeStats: Equatable {
    let years: Int
    let weeksLived: Int

    static let weeksPerYear = 52

    var totalWeeks: Int { years * Self.weeksPerYear }
    var weeksLeft: Int { max(totalWeeks - weeksLived, 0) }
    var fractionLived: Double {
        totalWeeks == 0 ? 0 : Double(weeksLived) / Double(totalWeeks)
    }
    /// Index of the week in progress, or nil once past the expectancy.
    var currentWeekIndex: Int? { weeksLived < totalWeeks ? weeksLived : nil }
}

enum LifeCalculator {
    static func stats(birthDate: Date,
                      lifeExpectancyYears: Int,
                      now: Date = Date(),
                      calendar: Calendar = .current) -> LifeStats {
        let years = max(lifeExpectancyYears, 1)
        let total = years * LifeStats.weeksPerYear
        let birth = calendar.startOfDay(for: birthDate)
        let today = calendar.startOfDay(for: now)

        guard today >= birth else { return LifeStats(years: years, weeksLived: 0) }

        let fullYears = max(calendar.dateComponents([.year], from: birth, to: today).year ?? 0, 0)
        let lastBirthday = calendar.date(byAdding: .year, value: fullYears, to: birth) ?? birth
        let daysSinceBirthday = max(calendar.dateComponents([.day], from: lastBirthday, to: today).day ?? 0, 0)
        // Days 364/365 of a year fold into week 52 (index 51).
        let weekInYear = min(daysSinceBirthday / 7, LifeStats.weeksPerYear - 1)

        let lived = min(fullYears * LifeStats.weeksPerYear + weekInYear, total)
        return LifeStats(years: years, weeksLived: lived)
    }
}

enum Fmt {
    private static let number: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    static func int(_ v: Int) -> String { number.string(from: NSNumber(value: v)) ?? "\(v)" }
    static func percent(_ v: Double) -> String { String(format: "%.1f%%", v * 100) }
}
