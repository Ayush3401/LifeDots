package io.github.ayush3401.lifedots

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.view.View
import kotlin.math.max
import kotlin.math.min

/** A scaled-down phone screen showing exactly what the wallpaper will draw. */
class PreviewView(context: Context, private val prefs: Prefs) : View(context) {
    private val clip = Path()
    private val outline = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = 0x33888888
    }

    private val screenW get() = min(resources.displayMetrics.widthPixels, resources.displayMetrics.heightPixels).toFloat()
    private val screenH get() = max(resources.displayMetrics.widthPixels, resources.displayMetrics.heightPixels).toFloat()

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val available = MeasureSpec.getSize(widthMeasureSpec)
        val phoneW = available * WIDTH_FRACTION
        setMeasuredDimension(available, (phoneW * screenH / screenW).toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val density = resources.displayMetrics.density
        val phoneW = width * WIDTH_FRACTION
        val phoneH = height.toFloat()
        val scale = phoneW / screenW
        val corner = 20 * density

        canvas.save()
        canvas.translate((width - phoneW) / 2, 0f)
        clip.reset()
        clip.addRoundRect(0f, 0f, phoneW, phoneH, corner, corner, Path.Direction.CW)
        canvas.clipPath(clip)
        DotsRenderer.draw(
            canvas, phoneW.toInt(), phoneH.toInt(), prefs.stats(), prefs.theme, prefs.showCaption,
            EdgeInsets(top = 32 * density * scale, bottom = 48 * density * scale),
            density * scale,
        )
        canvas.restore()

        outline.strokeWidth = density
        canvas.save()
        canvas.translate((width - phoneW) / 2, 0f)
        canvas.drawPath(clip, outline)
        canvas.restore()
    }

    private companion object {
        const val WIDTH_FRACTION = 0.6f
    }
}
