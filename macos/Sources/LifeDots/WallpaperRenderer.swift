import AppKit

struct Palette {
    let background: CGColor
    let lived: CGColor
    let remaining: CGColor
    let current: CGColor
    let text: CGColor
    let subtext: CGColor
}

extension Theme {
    var palette: Palette {
        switch self {
        case .dark:
            return Palette(background: .hex(0x0D0D0F), lived: .hex(0xEDEDED),
                           remaining: .hex(0x2C2C31), current: .hex(0xFF5F3A),
                           text: .hex(0xEDEDED), subtext: .hex(0x8A8A90))
        case .light:
            return Palette(background: .hex(0xF4F2EE), lived: .hex(0x1C1C1E),
                           remaining: .hex(0xD9D6D0), current: .hex(0xE5482B),
                           text: .hex(0x1C1C1E), subtext: .hex(0x6E6E73))
        }
    }
}

extension CGColor {
    static func hex(_ v: UInt32) -> CGColor {
        CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                green: CGFloat((v >> 8) & 0xFF) / 255,
                blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }
}

/// Everything the renderer needs about one display, in *pixels*.
struct RenderTarget: Hashable {
    let pixelWidth: Int
    let pixelHeight: Int
    let scale: CGFloat
    /// Space covered by the menu bar / notch / Dock, so dots never hide under them.
    let insetTop: CGFloat
    let insetBottom: CGFloat
    let insetLeft: CGFloat
    let insetRight: CGFloat
}

/// Picks the column count that makes the dots as large as possible for the
/// available area. It prefers a layout whose rows are all full (e.g. 104 × 40
/// = two years per row) if that costs at most 8% of dot size; a ragged last
/// row looks like a rendering bug.
struct GridLayout {
    let cols: Int
    let rows: Int
    let cell: CGFloat

    static func best(count: Int, in size: CGSize) -> GridLayout {
        guard count > 0, size.width > 0, size.height > 0 else {
            return GridLayout(cols: 1, rows: max(count, 1), cell: 0)
        }
        var candidates: [GridLayout] = []
        candidates.reserveCapacity(count)
        for cols in 1...count {
            let rows = (count + cols - 1) / cols
            let cell = min(size.width / CGFloat(cols), size.height / CGFloat(rows))
            candidates.append(GridLayout(cols: cols, rows: rows, cell: cell))
        }
        let maxCell = candidates.map(\.cell).max() ?? 0
        let fullRows = candidates
            .filter { count % $0.cols == 0 && $0.cell >= maxCell * 0.92 }
            .max { $0.cell < $1.cell }
        return fullRows ?? candidates.max { $0.cell < $1.cell }!
    }
}

enum WallpaperRenderer {
    static func render(stats: LifeStats, target: RenderTarget,
                       theme: Theme, showCaption: Bool) -> CGImage? {
        let w = target.pixelWidth, h = target.pixelHeight
        guard w > 0, h > 0,
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }

        let p = theme.palette
        let s = target.scale
        ctx.setFillColor(p.background)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.setShouldAntialias(true)

        // Usable area (CoreGraphics origin is bottom-left).
        let margin = 56 * s
        let captionBand: CGFloat = showCaption ? 96 * s : 0
        let area = CGRect(
            x: target.insetLeft + margin,
            y: target.insetBottom + margin + captionBand,
            width: CGFloat(w) - target.insetLeft - target.insetRight - 2 * margin,
            height: CGFloat(h) - target.insetTop - target.insetBottom - 2 * margin - captionBand)
        guard area.width > 0, area.height > 0 else { return ctx.makeImage() }

        let total = stats.totalWeeks
        let layout = GridLayout.best(count: total, in: area.size)
        let gridW = CGFloat(layout.cols) * layout.cell
        let gridH = CGFloat(layout.rows) * layout.cell
        let origin = CGPoint(x: area.midX - gridW / 2, y: area.midY - gridH / 2)
        let r = layout.cell * 0.34

        // One path per colour → three fills instead of thousands.
        let lived = CGMutablePath(), remaining = CGMutablePath(), current = CGMutablePath()
        for i in 0..<total {
            let row = i / layout.cols, col = i % layout.cols
            let cx = origin.x + (CGFloat(col) + 0.5) * layout.cell
            let cy = origin.y + gridH - (CGFloat(row) + 0.5) * layout.cell // fill top→bottom
            if i == stats.currentWeekIndex {
                let cr = r * 1.15
                current.addEllipse(in: CGRect(x: cx - cr, y: cy - cr, width: 2 * cr, height: 2 * cr))
            } else {
                (i < stats.weeksLived ? lived : remaining)
                    .addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
            }
        }
        ctx.setFillColor(p.remaining); ctx.addPath(remaining); ctx.fillPath()
        ctx.setFillColor(p.lived);     ctx.addPath(lived);     ctx.fillPath()
        ctx.setFillColor(p.current);   ctx.addPath(current);   ctx.fillPath()

        if showCaption {
            drawCaption(stats: stats, in: ctx, palette: p, scale: s,
                        centerX: origin.x + gridW / 2, top: origin.y - 30 * s)
        }
        return ctx.makeImage()
    }

    private static func drawCaption(stats: LifeStats, in ctx: CGContext, palette p: Palette,
                                    scale s: CGFloat, centerX: CGFloat, top: CGFloat) {
        let previous = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        defer { NSGraphicsContext.current = previous }

        let line1 = NSAttributedString(
            string: "\(Fmt.int(stats.weeksLived)) weeks lived   ·   \(Fmt.int(stats.weeksLeft)) weeks left",
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 22 * s, weight: .medium),
                         .foregroundColor: NSColor(cgColor: p.text) ?? .white,
                         .kern: 0.5 * s])
        let line2 = NSAttributedString(
            string: "\(Fmt.percent(stats.fractionLived)) of \(stats.years) years",
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 15 * s, weight: .regular),
                         .foregroundColor: NSColor(cgColor: p.subtext) ?? .gray,
                         .kern: 0.5 * s])

        let s1 = line1.size(), s2 = line2.size()
        let y1 = top - s1.height
        line1.draw(at: CGPoint(x: centerX - s1.width / 2, y: y1))
        line2.draw(at: CGPoint(x: centerX - s2.width / 2, y: y1 - 8 * s - s2.height))
    }
}
