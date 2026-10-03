package io.github.ayush3401.lifedots

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import kotlin.math.max
import kotlin.math.min

/** Space covered by system bars / cutouts, in pixels. */
data class EdgeInsets(
    val left: Float = 0f,
    val top: Float = 0f,
    val right: Float = 0f,
    val bottom: Float = 0f,
)

class Palette(
    val background: Int,
    val lived: Int,
    val remaining: Int,
    val current: Int,
    val text: Int,
    val subtext: Int,
)

/** Draws the dot grid. Used by the live wallpaper and by the in-app preview. */
object DotsRenderer {
    /**
     * Prefer layouts whose rows are all full if they cost at most 12% of dot
     * size: on a phone that picks 40 or 52 columns (52 = one year per row)
     * instead of a ragged last row.
     */
    private const val FULL_ROW_TOLERANCE = 0.88f

    fun palette(theme: Theme): Palette = when (theme) {
        Theme.DARK -> Palette(
            background = 0xFF0D0D0F.toInt(), lived = 0xFFEDEDED.toInt(),
            remaining = 0xFF2C2C31.toInt(), current = 0xFFFF5F3A.toInt(),
            text = 0xFFEDEDED.toInt(), subtext = 0xFF8A8A90.toInt(),
        )
        Theme.LIGHT -> Palette(
            background = 0xFFF4F2EE.toInt(), lived = 0xFF1C1C1E.toInt(),
            remaining = 0xFFD9D6D0.toInt(), current = 0xFFE5482B.toInt(),
            text = 0xFF1C1C1E.toInt(), subtext = 0xFF6E6E73.toInt(),
        )
    }

    data class Grid(val cols: Int, val rows: Int, val cell: Float)

    /** Column count that makes the dots as large as possible in the given area. */
    fun bestGrid(count: Int, width: Float, height: Float): Grid {
        if (count <= 0 || width <= 0f || height <= 0f) return Grid(1, max(count, 1), 0f)
        val all = (1..count).map { cols ->
            val rows = (count + cols - 1) / cols
            Grid(cols, rows, min(width / cols, height / rows))
        }
        val maxCell = all.maxOf { it.cell }
        return all.filter { count % it.cols == 0 && it.cell >= maxCell * FULL_ROW_TOLERANCE }
            .maxByOrNull { it.cell }
            ?: all.maxBy { it.cell }
    }

    fun draw(
        canvas: Canvas,
        width: Int,
        height: Int,
        stats: LifeStats?,
        theme: Theme,
        showCaption: Boolean,
        insets: EdgeInsets,
        density: Float,
    ) {
        val p = palette(theme)
        canvas.drawColor(p.background)

        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            fontFeatureSettings = "tnum"
            letterSpacing = 0.02f
        }

        if (stats == null) {
            text.color = p.subtext
            text.textSize = 15 * density
            canvas.drawText("Open LifeDots to set your birthday", width / 2f, height / 2f, text)
            return
        }

        val margin = 24 * density
        val captionBand = if (showCaption) 64 * density else 0f
        val areaLeft = insets.left + margin
        val areaTop = insets.top + margin
        val areaW = width - insets.left - insets.right - 2 * margin
        val areaH = height - insets.top - insets.bottom - 2 * margin - captionBand
        if (areaW <= 0f || areaH <= 0f) return

        val total = stats.totalWeeks
        val grid = bestGrid(total, areaW, areaH)
        val gridW = grid.cols * grid.cell
        val gridH = grid.rows * grid.cell
        val ox = areaLeft + (areaW - gridW) / 2
        val oy = areaTop + (areaH - gridH) / 2
        val r = grid.cell * 0.34f
        val current = stats.currentWeekIndex

        val dot = Paint(Paint.ANTI_ALIAS_FLAG)
        for (i in 0 until total) {
            val cx = ox + (i % grid.cols + 0.5f) * grid.cell
            val cy = oy + (i / grid.cols + 0.5f) * grid.cell
            dot.color = when {
                i == current -> p.current
                i < stats.weeksLived -> p.lived
                else -> p.remaining
            }
            canvas.drawCircle(cx, cy, if (i == current) r * 1.15f else r, dot)
        }

        if (showCaption) {
            val cx = ox + gridW / 2
            val baseline = oy + gridH + 30 * density
            text.color = p.text
            text.textSize = 15 * density
            canvas.drawText(
                "${Fmt.int(stats.weeksLived)} weeks lived  ·  ${Fmt.int(stats.weeksLeft)} weeks left",
                cx, baseline, text,
            )
            text.color = p.subtext
            text.textSize = 12 * density
            canvas.drawText(
                "${Fmt.percent(stats.fractionLived)} of ${stats.years} years",
                cx, baseline + 20 * density, text,
            )
        }
    }
}
