import SwiftUI
import WidgetKit

struct LifeEntry: TimelineEntry {
    let date: Date
    let settings: LifeSettings
}

/// One entry per day, refreshed just after midnight. The app also reloads
/// widgets whenever a setting changes.
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LifeEntry {
        LifeEntry(date: Date(), settings: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeEntry) -> Void) {
        let saved = SharedStore.loadSettings()
        completion(LifeEntry(date: Date(), settings: saved.birthDate == nil ? .preview : saved))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        completion(Timeline(entries: [LifeEntry(date: now, settings: SharedStore.loadSettings())],
                            policy: .after(nextMidnight.addingTimeInterval(60))))
    }
}

struct LifeDotsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LifeEntry

    private var stats: LifeStats? { entry.settings.stats(now: entry.date) }
    private var palette: Palette { entry.settings.theme.palette }
    private var isAccessory: Bool {
        [.accessoryCircular, .accessoryRectangular, .accessoryInline].contains(family)
    }

    var body: some View {
        content
            .containerBackground(for: .widget) {
                isAccessory ? Color.clear : Color(uiColor: palette.background)
            }
    }

    @ViewBuilder private var content: some View {
        if let stats {
            switch family {
            case .accessoryCircular:
                Gauge(value: stats.fractionLived) {
                    Text("Life")
                } currentValueLabel: {
                    Text("\(Int((stats.fractionLived * 100).rounded()))%")
                }
                .gaugeStyle(.accessoryCircularCapacity)

            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Fmt.int(stats.weeksLeft)) weeks left").font(.headline).monospacedDigit()
                    ProgressView(value: stats.fractionLived)
                    Text("\(Fmt.int(stats.weeksLived)) lived · \(Fmt.percent(stats.fractionLived))")
                        .font(.caption).monospacedDigit()
                }

            case .accessoryInline:
                Text("\(Fmt.int(stats.weeksLeft)) weeks left")

            case .systemSmall:
                VStack(alignment: .leading, spacing: 4) {
                    Text("LifeDots").font(.caption).foregroundStyle(Color(uiColor: palette.subtext))
                    Spacer(minLength: 0)
                    Text(Fmt.int(stats.weeksLeft))
                        .font(.system(size: 34, weight: .semibold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(Color(uiColor: palette.text))
                        .minimumScaleFactor(0.6)
                    Text("weeks left").font(.caption).foregroundStyle(Color(uiColor: palette.subtext))
                    ProgressView(value: stats.fractionLived).tint(Color(uiColor: palette.current))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            default: // medium & large: the full grid
                VStack(spacing: 6) {
                    DotsImage(settings: entry.settings, date: entry.date)
                    Text("\(Fmt.int(stats.weeksLived)) lived · \(Fmt.int(stats.weeksLeft)) left · \(Fmt.percent(stats.fractionLived))")
                        .font(.caption2).monospacedDigit()
                        .foregroundStyle(Color(uiColor: palette.subtext))
                }
            }
        } else {
            Text("Open LifeDots to set your birthday")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(isAccessory ? Color.primary : Color(uiColor: palette.subtext))
        }
    }
}

/// The dot grid rendered as an image at the widget's exact size.
struct DotsImage: View {
    let settings: LifeSettings
    let date: Date
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geo in
            Image(uiImage: DotsRenderer.image(size: geo.size, scale: displayScale, settings: settings,
                                              date: date, showCaption: false, margin: 0))
        }
    }
}

struct LifeDotsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LifeDots", provider: Provider()) { entry in
            LifeDotsWidgetView(entry: entry)
        }
        .configurationDisplayName("LifeDots")
        .description("Your life in weeks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct LifeDotsWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeDotsWidget()
    }
}
