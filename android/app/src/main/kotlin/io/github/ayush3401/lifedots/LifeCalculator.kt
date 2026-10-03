package io.github.ayush3401.lifedots

import java.text.NumberFormat
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.util.Locale

/**
 * Life on the classic "life in weeks" grid: every year is exactly 52 dots and
 * week N of a year starts N*7 days after that year's birthday. Same model as
 * the macOS app, so both show identical numbers.
 */
data class LifeStats(val years: Int, val weeksLived: Int) {
    val totalWeeks: Int get() = years * WEEKS_PER_YEAR
    val weeksLeft: Int get() = (totalWeeks - weeksLived).coerceAtLeast(0)
    val fractionLived: Double get() = if (totalWeeks == 0) 0.0 else weeksLived.toDouble() / totalWeeks
    /** Index of the week in progress, or null once past the expectancy. */
    val currentWeekIndex: Int? get() = if (weeksLived < totalWeeks) weeksLived else null

    companion object {
        const val WEEKS_PER_YEAR = 52
    }
}

object LifeCalculator {
    fun stats(birthDate: LocalDate, lifeExpectancyYears: Int, today: LocalDate = LocalDate.now()): LifeStats {
        val years = lifeExpectancyYears.coerceAtLeast(1)
        val total = years * LifeStats.WEEKS_PER_YEAR
        if (today.isBefore(birthDate)) return LifeStats(years, 0)

        val fullYears = ChronoUnit.YEARS.between(birthDate, today).toInt()
        val lastBirthday = birthDate.plusYears(fullYears.toLong())
        val daysSinceBirthday = ChronoUnit.DAYS.between(lastBirthday, today).toInt()
        // Days 364/365 of a year fold into week 52 (index 51).
        val weekInYear = minOf(daysSinceBirthday / 7, LifeStats.WEEKS_PER_YEAR - 1)

        return LifeStats(years, minOf(fullYears * LifeStats.WEEKS_PER_YEAR + weekInYear, total))
    }
}

object Fmt {
    fun int(v: Int): String = NumberFormat.getIntegerInstance().format(v)
    fun percent(v: Double): String = String.format(Locale.getDefault(), "%.1f%%", v * 100)
}
