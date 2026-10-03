package io.github.ayush3401.lifedots

import android.app.Activity
import android.app.DatePickerDialog
import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.view.WindowInsets
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import kotlin.math.roundToInt

/**
 * Settings screen. Plain platform views on purpose: no AndroidX / Compose
 * dependencies keeps the build simple and the APK tiny.
 */
class MainActivity : Activity(), SharedPreferences.OnSharedPreferenceChangeListener {
    private lateinit var prefs: Prefs
    private lateinit var preview: PreviewView
    private lateinit var statsText: TextView
    private lateinit var birthButton: Button
    private lateinit var yearsLabel: TextView
    private lateinit var yearsSeek: SeekBar
    private lateinit var applyButton: Button

    private val dateFormat = DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = Prefs(this)
        setContentView(buildUi())
    }

    override fun onStart() {
        super.onStart()
        prefs.registerListener(this)
    }

    override fun onResume() {
        super.onResume()
        refresh() // also picks up "wallpaper was just set" after returning from the picker
    }

    override fun onStop() {
        prefs.unregisterListener(this)
        super.onStop()
    }

    override fun onSharedPreferenceChanged(sp: SharedPreferences?, key: String?) = refresh()

    // MARK: UI

    private fun dp(v: Int) = (v * resources.displayMetrics.density).roundToInt()

    private fun label(text: String) = TextView(this).apply {
        this.text = text
        alpha = 0.7f
        setPadding(0, dp(20), 0, dp(6))
    }

    private fun buildUi(): View {
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(16), dp(24), dp(32))
        }

        column.addView(TextView(this).apply {
            text = getString(R.string.app_name)
            textSize = 30f
            typeface = Typeface.DEFAULT_BOLD
        })
        column.addView(TextView(this).apply {
            text = getString(R.string.tagline)
            alpha = 0.7f
            setPadding(0, dp(4), 0, dp(20))
        })

        preview = PreviewView(this, prefs)
        column.addView(preview, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))

        statsText = TextView(this).apply {
            gravity = Gravity.CENTER
            fontFeatureSettings = "tnum"
            setPadding(0, dp(12), 0, 0)
        }
        column.addView(statsText)

        column.addView(label("Date of birth"))
        birthButton = Button(this).apply { setOnClickListener { pickBirthday() } }
        column.addView(birthButton, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))

        yearsLabel = label("")
        column.addView(yearsLabel)
        yearsSeek = SeekBar(this).apply {
            min = 1
            max = 120
            progress = prefs.lifeExpectancyYears
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
                    if (fromUser) prefs.lifeExpectancyYears = progress
                }
                override fun onStartTrackingTouch(seekBar: SeekBar) {}
                override fun onStopTrackingTouch(seekBar: SeekBar) {}
            })
        }
        column.addView(yearsSeek, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))

        column.addView(label("Theme"))
        val themeGroup = RadioGroup(this).apply { orientation = RadioGroup.HORIZONTAL }
        for (t in Theme.entries) {
            themeGroup.addView(RadioButton(this).apply {
                id = View.generateViewId()
                text = t.title
                isChecked = prefs.theme == t
                setPadding(dp(4), 0, dp(24), 0)
                setOnClickListener { prefs.theme = t }
            })
        }
        column.addView(themeGroup)

        @Suppress("UseSwitchCompatOrMaterialCode") // no AppCompat on purpose
        val captionSwitch = Switch(this).apply {
            text = "Show weeks lived / left"
            isChecked = prefs.showCaption
            setOnCheckedChangeListener { _, checked -> prefs.showCaption = checked }
        }
        column.addView(captionSwitch, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(20) })

        applyButton = Button(this).apply { setOnClickListener { applyWallpaper() } }
        column.addView(applyButton, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { topMargin = dp(28) })

        val scroll = ScrollView(this).apply {
            addView(column)
            clipToPadding = false
        }
        // targetSdk 35+ draws edge-to-edge: pad content away from the system bars.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            scroll.setOnApplyWindowInsetsListener { v, insets ->
                val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                insets
            }
        }
        return scroll
    }

    private fun refresh() {
        birthButton.text = prefs.birthDate?.format(dateFormat) ?: "Set your birthday"
        yearsLabel.text = "Life expectancy: ${prefs.lifeExpectancyYears} years"
        if (yearsSeek.progress != prefs.lifeExpectancyYears) yearsSeek.progress = prefs.lifeExpectancyYears

        val stats = prefs.stats()
        statsText.text = stats?.let {
            "${Fmt.int(it.weeksLived)} weeks lived · ${Fmt.int(it.weeksLeft)} left · ${Fmt.percent(it.fractionLived)}"
        } ?: "Set your birthday to see your weeks"

        applyButton.text = if (isOurWallpaperActive()) "LifeDots is your wallpaper ✓" else "Set as wallpaper"
        preview.invalidate()
    }

    // MARK: Actions

    private fun pickBirthday(then: (() -> Unit)? = null) {
        val initial = prefs.birthDate ?: LocalDate.now().minusYears(25)
        DatePickerDialog(
            this,
            { _, year, month, day ->
                prefs.birthDate = LocalDate.of(year, month + 1, day)
                then?.invoke()
            },
            initial.year, initial.monthValue - 1, initial.dayOfMonth,
        ).apply {
            datePicker.maxDate = LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli() +
                24 * 60 * 60 * 1000 - 1
        }.show()
    }

    private fun isOurWallpaperActive(): Boolean =
        WallpaperManager.getInstance(this).wallpaperInfo?.packageName == packageName

    private fun applyWallpaper() {
        if (prefs.birthDate == null) {
            pickBirthday { applyWallpaper() }
            return
        }
        val direct = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).putExtra(
            WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
            ComponentName(this, LifeDotsWallpaperService::class.java),
        )
        try {
            startActivity(direct)
        } catch (e: ActivityNotFoundException) {
            // Some OEM launchers lack the direct screen; fall back to the generic picker.
            try {
                startActivity(Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))
            } catch (e2: ActivityNotFoundException) {
                Toast.makeText(this, "This device doesn't support live wallpapers", Toast.LENGTH_LONG).show()
            }
        }
    }
}
