package io.github.ayush3401.lifedots

import android.content.Context
import android.content.SharedPreferences
import java.time.LocalDate

enum class Theme(val title: String) {
    DARK("Dark"),
    LIGHT("Light"),
}

/**
 * Settings shared by the settings screen and the wallpaper service. Both run in
 * the same process, so a change made in the app reaches the wallpaper through
 * the SharedPreferences change listener and it redraws immediately.
 */
class Prefs(context: Context) {
    private val sp: SharedPreferences =
        context.applicationContext.getSharedPreferences("lifedots", Context.MODE_PRIVATE)

    var birthDate: LocalDate?
        get() = if (sp.contains(KEY_BIRTH)) LocalDate.ofEpochDay(sp.getLong(KEY_BIRTH, 0)) else null
        set(value) {
            sp.edit().apply {
                if (value == null) remove(KEY_BIRTH) else putLong(KEY_BIRTH, value.toEpochDay())
            }.apply()
        }

    var lifeExpectancyYears: Int
        get() = sp.getInt(KEY_YEARS, 80).coerceIn(1, 120)
        set(value) = sp.edit().putInt(KEY_YEARS, value.coerceIn(1, 120)).apply()

    var theme: Theme
        get() = Theme.entries.firstOrNull { it.name == sp.getString(KEY_THEME, null) } ?: Theme.DARK
        set(value) = sp.edit().putString(KEY_THEME, value.name).apply()

    var showCaption: Boolean
        get() = sp.getBoolean(KEY_CAPTION, true)
        set(value) = sp.edit().putBoolean(KEY_CAPTION, value).apply()

    fun stats(): LifeStats? = birthDate?.let { LifeCalculator.stats(it, lifeExpectancyYears) }

    // SharedPreferences keeps listeners weakly: callers must hold a strong reference.
    fun registerListener(l: SharedPreferences.OnSharedPreferenceChangeListener) =
        sp.registerOnSharedPreferenceChangeListener(l)

    fun unregisterListener(l: SharedPreferences.OnSharedPreferenceChangeListener) =
        sp.unregisterOnSharedPreferenceChangeListener(l)

    private companion object {
        const val KEY_BIRTH = "birthEpochDay"
        const val KEY_YEARS = "lifeExpectancyYears"
        const val KEY_THEME = "theme"
        const val KEY_CAPTION = "showCaption"
    }
}
