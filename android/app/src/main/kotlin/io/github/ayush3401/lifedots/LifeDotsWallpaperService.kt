package io.github.ayush3401.lifedots

import android.app.WallpaperColors
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import android.view.WindowInsets
import kotlin.math.max

/**
 * Live wallpaper: instead of writing an image file, the app *is* the wallpaper
 * and redraws itself whenever it becomes visible (screen on, back to home).
 * So it is always current, with no background job and no stored images.
 */
class LifeDotsWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = DotsEngine()

    private inner class DotsEngine : Engine(), SharedPreferences.OnSharedPreferenceChangeListener {
        private val prefs = Prefs(this@LifeDotsWallpaperService)
        private var insets = EdgeInsets()
        private var colorsTheme: Theme = prefs.theme

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            setTouchEventsEnabled(false)
            prefs.registerListener(this)
        }

        override fun onDestroy() {
            prefs.unregisterListener(this)
            super.onDestroy()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            if (visible) draw()
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            draw()
        }

        override fun onSurfaceRedrawNeeded(holder: SurfaceHolder) {
            super.onSurfaceRedrawNeeded(holder)
            draw()
        }

        override fun onApplyWindowInsets(windowInsets: WindowInsets) {
            super.onApplyWindowInsets(windowInsets)
            insets = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val i = windowInsets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                EdgeInsets(i.left.toFloat(), i.top.toFloat(), i.right.toFloat(), i.bottom.toFloat())
            } else {
                @Suppress("DEPRECATION")
                EdgeInsets(
                    windowInsets.systemWindowInsetLeft.toFloat(), windowInsets.systemWindowInsetTop.toFloat(),
                    windowInsets.systemWindowInsetRight.toFloat(), windowInsets.systemWindowInsetBottom.toFloat(),
                )
            }
            draw()
        }

        override fun onSharedPreferenceChanged(sp: SharedPreferences?, key: String?) {
            if (prefs.theme != colorsTheme) {
                colorsTheme = prefs.theme
                notifyColorsChanged() // lets Material You re-derive system colours
            }
            draw()
        }

        /** Tells the system our colours, for Material You theming and dark/light hints. */
        override fun onComputeColors(): WallpaperColors {
            val p = DotsRenderer.palette(prefs.theme)
            return WallpaperColors(Color.valueOf(p.background), Color.valueOf(p.lived), Color.valueOf(p.current))
        }

        private fun draw() {
            val holder = surfaceHolder ?: return
            val frame = holder.surfaceFrame
            if (frame.width() <= 0 || frame.height() <= 0) return
            val canvas = try {
                holder.lockHardwareCanvas()
            } catch (e: Exception) {
                null
            } ?: return

            val density = resources.displayMetrics.density
            // Some launchers never send insets; keep clear of status/nav bars anyway.
            val safe = insets.copy(
                top = max(insets.top, 32 * density),
                bottom = max(insets.bottom, 48 * density),
            )
            try {
                DotsRenderer.draw(
                    canvas, frame.width(), frame.height(), prefs.stats(),
                    prefs.theme, prefs.showCaption, safe, density,
                )
            } finally {
                holder.unlockCanvasAndPost(canvas)
            }
        }
    }
}
