import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Renders one PNG per display and hands it to macOS.
///
/// Design notes:
/// - macOS caches the desktop picture by URL, so every render gets a fresh
///   file name; reusing one path would leave the old image on screen.
/// - `setDesktopImageURL` only affects the *current* Space, so on every Space
///   switch the latest image is re-applied (cheap: no re-render).
/// - A signature of (stats, settings, display geometry) means the periodic
///   timer only re-renders when something visible actually changed.
final class WallpaperManager {
    private let directory: URL
    private var currentURLs: [CGDirectDisplayID: URL] = [:]
    private var lastSignature: String?

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("LifeDots/Wallpapers", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func update(stats: LifeStats, theme: Theme, showCaption: Bool, force: Bool = false) {
        let screens = NSScreen.screens.compactMap { s in s.displayID.map { ($0, s, Self.target(for: s)) } }
        let signature = "\(stats.weeksLived)|\(stats.years)|\(theme.rawValue)|\(showCaption)|"
            + screens.map { "\($0.0):\($0.2.hashValue)" }.sorted().joined(separator: ",")

        guard force || signature != lastSignature else {
            reapply()
            return
        }

        var newURLs: [CGDirectDisplayID: URL] = [:]
        let stamp = Int(Date().timeIntervalSince1970)
        for (id, screen, target) in screens {
            guard let image = WallpaperRenderer.render(stats: stats, target: target,
                                                       theme: theme, showCaption: showCaption)
            else { continue }
            let url = directory.appendingPathComponent("lifedots-\(id)-\(stamp).png")
            guard Self.writePNG(image, to: url) else { continue }
            if set(url, on: screen) { newURLs[id] = url }
        }

        if !newURLs.isEmpty {
            currentURLs = newURLs
            lastSignature = signature
            cleanUp(keeping: Set(newURLs.values))
        }
    }

    /// Re-apply the latest images without rendering (e.g. after a Space switch).
    func reapply() {
        for screen in NSScreen.screens {
            guard let id = screen.displayID, let url = currentURLs[id],
                  NSWorkspace.shared.desktopImageURL(for: screen) != url else { continue }
            _ = set(url, on: screen)
        }
    }

    // MARK: - Helpers

    private func set(_ url: URL, on screen: NSScreen) -> Bool {
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true,
        ]
        do {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: options)
            return true
        } catch {
            NSLog("LifeDots: failed to set wallpaper: \(error)")
            return false
        }
    }

    private static func target(for screen: NSScreen) -> RenderTarget {
        let scale = screen.backingScaleFactor
        let frame = screen.frame, visible = screen.visibleFrame
        let notchTop = screen.safeAreaInsets.top
        return RenderTarget(
            pixelWidth: Int((frame.width * scale).rounded()),
            pixelHeight: Int((frame.height * scale).rounded()),
            scale: scale,
            insetTop: max(frame.maxY - visible.maxY, notchTop) * scale,
            insetBottom: (visible.minY - frame.minY) * scale,
            insetLeft: (visible.minX - frame.minX) * scale,
            insetRight: (frame.maxX - visible.maxX) * scale)
    }

    private static func writePNG(_ image: CGImage, to url: URL) -> Bool {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return false }
        CGImageDestinationAddImage(dest, image, nil)
        return CGImageDestinationFinalize(dest)
    }

    private func cleanUp(keeping keep: Set<URL>) {
        let fm = FileManager.default
        let keepPaths = Set(keep.map(\.standardizedFileURL.path))
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "png" && !keepPaths.contains(file.standardizedFileURL.path) {
            try? fm.removeItem(at: file)
        }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
