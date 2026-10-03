import AppKit

/// Settings window built with plain AppKit.
///
/// Deliberately not SwiftUI: on newer SDKs `@State` & co. are compiler macros
/// whose plugin ships only with full Xcode, so a SwiftUI view fails to build
/// with just the Command Line Tools. AppKit has no such dependency.
final class SettingsWindowController: NSWindowController {
    private let settings: Settings

    private let datePicker = NSDatePicker()
    private let stepper = NSStepper()
    private let yearsLabel = NSTextField(labelWithString: "")
    private let themeControl = NSSegmentedControl(labels: Theme.allCases.map(\.title),
                                                  trackingMode: .selectOne, target: nil, action: nil)
    private let captionCheckbox = NSButton(checkboxWithTitle: "Show weeks lived / left under the dots",
                                           target: nil, action: nil)
    private let livedValue = NSTextField(labelWithString: "")
    private let leftValue = NSTextField(labelWithString: "")
    private let progressValue = NSTextField(labelWithString: "")
    private let doneButton = NSButton(title: "Done", target: nil, action: nil)

    init(settings: Settings) {
        self.settings = settings
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "LifeDots"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildUI()
        window.center()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show() {
        loadValues()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - UI

    private func buildUI() {
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerElements = .yearMonthDay
        datePicker.maxDate = Date()
        datePicker.target = self
        datePicker.action = #selector(dateChanged)

        stepper.minValue = 1
        stepper.maxValue = 120
        stepper.increment = 1
        stepper.valueWraps = false
        stepper.target = self
        stepper.action = #selector(expectancyChanged)

        themeControl.target = self
        themeControl.action = #selector(themeChanged)

        captionCheckbox.target = self
        captionCheckbox.action = #selector(captionChanged)

        for field in [livedValue, leftValue, progressValue, yearsLabel] {
            field.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }

        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.target = self
        doneButton.action = #selector(done)

        let expectancyRow = NSStackView(views: [yearsLabel, stepper])
        expectancyRow.spacing = 8

        let grid = NSGridView(views: [
            [label("Date of birth"), datePicker],
            [label("Life expectancy"), expectancyRow],
            [label("Theme"), themeControl],
            [NSGridCell.emptyContentView, captionCheckbox],
            [label("Weeks lived"), livedValue],
            [label("Weeks left"), leftValue],
            [label("Progress"), progressValue],
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 12
        grid.rowAlignment = .firstBaseline
        grid.column(at: 0).xPlacement = .trailing
        grid.row(at: 4).topPadding = 10   // gap between inputs and the stats

        let content = NSView()
        for v in [grid, doneButton] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(v)
        }
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            doneButton.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
        ])
        window?.contentView = content
        window?.setContentSize(content.fittingSize)
    }

    private func label(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.textColor = .secondaryLabelColor
        return l
    }

    private func loadValues() {
        let fallback = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        datePicker.maxDate = Date()
        datePicker.dateValue = settings.birthDate ?? fallback
        stepper.integerValue = settings.lifeExpectancyYears
        themeControl.selectedSegment = Theme.allCases.firstIndex(of: settings.theme) ?? 0
        captionCheckbox.state = settings.showCaption ? .on : .off
        doneButton.title = settings.birthDate == nil ? "Set Wallpaper" : "Done"
        updateLabels()
    }

    private func updateLabels() {
        yearsLabel.stringValue = "\(stepper.integerValue) years"
        let stats = LifeCalculator.stats(birthDate: datePicker.dateValue,
                                         lifeExpectancyYears: stepper.integerValue)
        livedValue.stringValue = Fmt.int(stats.weeksLived)
        leftValue.stringValue = Fmt.int(stats.weeksLeft)
        progressValue.stringValue = Fmt.percent(stats.fractionLived)
    }

    // MARK: - Actions

    @objc private func dateChanged(_ sender: Any?) {
        // Live-update only after a birthday has been confirmed once.
        if settings.birthDate != nil { settings.birthDate = datePicker.dateValue }
        updateLabels()
    }

    @objc private func expectancyChanged(_ sender: Any?) {
        settings.lifeExpectancyYears = stepper.integerValue
        updateLabels()
    }

    @objc private func themeChanged(_ sender: Any?) {
        let i = themeControl.selectedSegment
        if Theme.allCases.indices.contains(i) { settings.theme = Theme.allCases[i] }
    }

    @objc private func captionChanged(_ sender: Any?) {
        settings.showCaption = captionCheckbox.state == .on
    }

    @objc private func done(_ sender: Any?) {
        settings.birthDate = datePicker.dateValue
        doneButton.title = "Done"
        close()
    }
}
