import AppKit
import Combine
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings.shared
    private let wallpaper = WallpaperManager()

    private var statusItem: NSStatusItem!
    private let livedItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let leftItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private lazy var settingsWindow = SettingsWindowController(settings: settings)
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()
        observeSystem()
        refresh()
        if settings.birthDate == nil { showSettings() }
    }

    // MARK: - Menu bar

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "circle.grid.3x3.fill",
                                           accessibilityDescription: "LifeDots")

        let menu = NSMenu()
        livedItem.isEnabled = false
        leftItem.isEnabled = false
        menu.addItem(livedItem)
        menu.addItem(leftItem)
        menu.addItem(.separator())
        menu.addItem(item("Update Wallpaper Now", #selector(forceRefresh), "r"))
        menu.addItem(item("Settings…", #selector(showSettings), ","))
        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(item("Quit LifeDots", #selector(NSApplication.terminate(_:)), "q", target: NSApp))
        statusItem.menu = menu
        updateMenu(stats: nil)
    }

    private func item(_ title: String, _ action: Selector, _ key: String, target: AnyObject? = nil) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = target ?? self
        return i
    }

    private func updateMenu(stats: LifeStats?) {
        if let stats {
            livedItem.title = "\(Fmt.int(stats.weeksLived)) weeks lived (\(Fmt.percent(stats.fractionLived)))"
            leftItem.title = "\(Fmt.int(stats.weeksLeft)) weeks left of \(stats.years) years"
        } else {
            livedItem.title = "Set your birthday in Settings…"
            leftItem.title = ""
        }
        leftItem.isHidden = stats == nil
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    // MARK: - Triggers

    /// Things that can change what the wallpaper should show.
    private func observeSystem() {
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(refreshNotification), name: NSWorkspace.didWakeNotification, object: nil)
        ws.addObserver(self, selector: #selector(spaceChanged), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(refreshNotification), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        nc.addObserver(self, selector: #selector(refreshNotification), name: .NSCalendarDayChanged, object: nil)
        nc.addObserver(self, selector: #selector(refreshNotification), name: .NSSystemTimeZoneDidChange, object: nil)

        // Safety net (e.g. a week boundary while the Mac stays awake). Cheap: it
        // only re-renders when the computed signature changes.
        let t = Timer(timeInterval: 30 * 60, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        t.tolerance = 60
        RunLoop.main.add(t, forMode: .common)
        timer = t

        // Settings edits; debounced so scrolling through a date doesn't re-render per click.
        settings.objectWillChange
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    @objc private func refreshNotification(_ n: Notification) { refresh() }
    @objc private func timerFired(_ t: Timer) { refresh() }
    @objc private func spaceChanged(_ n: Notification) { wallpaper.reapply() }
    @objc private func forceRefresh() { refresh(force: true) }

    private func refresh(force: Bool = false) {
        let stats = settings.currentStats()
        updateMenu(stats: stats)
        guard let stats else { return }
        wallpaper.update(stats: stats, theme: settings.theme,
                         showCaption: settings.showCaption, force: force)
    }

    // MARK: - Settings window

    @objc private func showSettings() {
        settingsWindow.show()
    }

    // MARK: - Launch at login

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = "Run LifeDots from the bundled LifeDots.app (ideally in /Applications), not via `swift run`.\n\n\(error.localizedDescription)"
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
        updateMenu(stats: settings.currentStats())
    }
}
