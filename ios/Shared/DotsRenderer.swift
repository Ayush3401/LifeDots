import UIKit

struct Palette {
    let background: UIColor
    let lived: UIColor
    let remaining: UIColor
    let current: UIColor
    let text: UIColor
    let subtext: UIColor
}

extension Theme {
    var palette: Palette {
        switch self {
        case .dark:
            return Palette(background: UIColor(hex: 0x0D0D0F), lived: UIColor(hex: 0xEDEDED),
                           remaining: UIColor(hex: 0x2C2C31), current: UIColor(hex: 0xFF5F3A),
                           text: UIColor(hex: 0xEDEDED), subtext: UIColor(hex: 0x8A8A90))
        case .light:
            return Palette(background: UIColor(hex: 0xF4F2EE), lived: UIColor(hex: 0x1C1C1E),
                           remaining: UIColor(hex: 0xD9D6D0), current: UIColor(hex: 0xE5482B),
                           text: UIColor(hex: 0x1C1C1E), subtext: UIColor(hex: 0x6E6E73))
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

/// Picks the column count that makes the dots as large as possible. Prefers
/// layouts with only full rows (e.g. 52 = one year per row) when that costs at
/// most 12% of dot size. Same rule as the Android app.
struct GridLayout {
    let cols: Int
    let rows: Int
    let cell: CGFloat

    static func best(count: Int, in size: CGSize) -> GridLayout {
        guard count > 0, size.width > 0, size.height > 0 else {
            return GridLayout(cols: 1, rows: max(count, 1), cell: 0)
        }
        let all = (1...count).map { cols -> GridLayout in
            let rows = (count + cols - 1) / cols
            return GridLayout(cols: cols, rows: rows,
                              cell: min(size.width / CGFloat(cols), size.height / CGFloat(rows)))
        }
        let maxCell = all.map(\.cell).max() ?? 0
        return all.filter { count % $0.cols == 0 && $0.cell >= maxCell * 0.88 }.max { $0.cell < $1.cell }
            ?? all.max { $0.cell < $1.cell }!
    }
}

enum DotsRenderer {
    /// Draws into a context with a top-left origin.
    /// - Parameter unit: context units per point (1 when drawing in points, the
    ///   screen scale when drawing a full-resolution pixel image).
    static func draw(in ctx: CGContext, size: CGSize, stats: LifeStats?, theme: Theme, showCaption: Bool,
                     insets: UIEdgeInsets = .zero, unit: CGFloat = 1, margin: CGFloat = 24) {
        let p = theme.palette
        ctx.setFillColor(p.background.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))

        UIGraphicsPushContext(ctx) // lets UIKit text drawing target this context
        defer { UIGraphicsPopContext() }

        guard let stats else {
            drawCentered("Open LifeDots to set your birthday",
                         font: .systemFont(ofSize: 15 * unit, weight: .medium), color: p.subtext,
                         centerX: size.width / 2, y: size.height / 2 - 9 * unit)
            return
        }

        let m = margin * unit
        let captionBand: CGFloat = showCaption ? 56 * unit : 0
        let area = CGRect(x: insets.left + m, y: insets.top + m,
                          width: size.width - insets.left - insets.right - 2 * m,
                          height: size.height - insets.top - insets.bottom - 2 * m - captionBand)
        guard area.width > 0, area.height > 0 else { return }

        let total = stats.totalWeeks
        let layout = GridLayout.best(count: total, in: area.size)
        let gridW = CGFloat(layout.cols) * layout.cell
        let gridH = CGFloat(layout.rows) * layout.cell
        let ox = area.midX - gridW / 2
        let oy = area.midY - gridH / 2
        let r = layout.cell * 0.34

        // One path per colour → three fills instead of thousands.
        let lived = CGMutablePath(), remaining = CGMutablePath(), current = CGMutablePath()
        for i in 0..<total {
            let cx = ox + (CGFloat(i % layout.cols) + 0.5) * layout.cell
            let cy = oy + (CGFloat(i / layout.cols) + 0.5) * layout.cell
            if i == stats.currentWeekIndex {
                let cr = r * 1.15
                current.addEllipse(in: CGRect(x: cx - cr, y: cy - cr, width: 2 * cr, height: 2 * cr))
            } else {
                (i < stats.weeksLived ? lived : remaining)
                    .addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
            }
        }
        ctx.setFillColor(p.remaining.cgColor); ctx.addPath(remaining); ctx.fillPath()
        ctx.setFillColor(p.lived.cgColor);     ctx.addPath(lived);     ctx.fillPath()
        ctx.setFillColor(p.current.cgColor);   ctx.addPath(current);   ctx.fillPath()

        if showCaption {
            let cx = ox + gridW / 2
            var y = oy + gridH + 16 * unit
            y += drawCentered("\(Fmt.int(stats.weeksLived)) weeks lived  ·  \(Fmt.int(stats.weeksLeft)) weeks left",
                              font: .monospacedDigitSystemFont(ofSize: 15 * unit, weight: .medium),
                              color: p.text, centerX: cx, y: y) + 3 * unit
            drawCentered("\(Fmt.percent(stats.fractionLived)) of \(stats.years) years",
                         font: .monospacedDigitSystemFont(ofSize: 12 * unit, weight: .regular),
                         color: p.subtext, centerX: cx, y: y)
        }
    }

    @discardableResult
    private static func drawCentered(_ string: String, font: UIFont, color: UIColor,
                                     centerX: CGFloat, y: CGFloat) -> CGFloat {
        let text = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color])
        let size = text.size()
        text.draw(at: CGPoint(x: centerX - size.width / 2, y: y))
        return size.height
    }

    /// Renders to an image. `size` is in points; `scale` is pixels per point.
    static func image(size: CGSize, scale: CGFloat, settings: LifeSettings, date: Date = Date(),
                      showCaption: Bool, insets: UIEdgeInsets = .zero, unit: CGFloat = 1,
                      margin: CGFloat = 24) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { r in
            draw(in: r.cgContext, size: size, stats: settings.stats(now: date), theme: settings.theme,
                 showCaption: showCaption, insets: insets, unit: unit, margin: margin)
        }
    }

    /// Full-resolution Lock Screen wallpaper for the given screen.
    static func wallpaper(settings: LifeSettings, screen: ScreenInfo, date: Date = Date()) -> UIImage {
        let size = CGSize(width: screen.pixelWidth, height: screen.pixelHeight)
        return image(size: size, scale: 1, settings: settings, date: date, showCaption: settings.showCaption,
                     insets: lockScreenInsets(for: size), unit: CGFloat(screen.scale))
    }

    /// Keeps the dots clear of the Lock Screen clock (top) and the
    /// flashlight / camera buttons (bottom).
    static func lockScreenInsets(for size: CGSize) -> UIEdgeInsets {
        UIEdgeInsets(top: size.height * 0.30, left: 0, bottom: size.height * 0.13, right: 0)
    }
}
