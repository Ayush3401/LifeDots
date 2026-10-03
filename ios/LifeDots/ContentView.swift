import Photos
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var alertText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhonePreview(settings: model.settings, screen: model.screen)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    if let stats = model.settings.stats() {
                        Text("\(Fmt.int(stats.weeksLived)) weeks lived · \(Fmt.int(stats.weeksLeft)) left · \(Fmt.percent(stats.fractionLived))")
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    }
                }

                Section("You") {
                    DatePicker("Date of birth", selection: birthDate, in: ...Date(), displayedComponents: .date)
                    Stepper("Life expectancy: \(model.settings.lifeExpectancyYears) years",
                            value: $model.settings.lifeExpectancyYears, in: 1...120)
                }

                Section("Look") {
                    Picker("Theme", selection: $model.settings.theme) {
                        ForEach(Theme.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Show weeks lived / left", isOn: $model.settings.showCaption)
                }

                Section {
                    NavigationLink("Update wallpaper automatically") { SetupGuideView() }
                    Button("Save wallpaper to Photos", action: saveToPhotos)
                        .disabled(model.settings.birthDate == nil)
                } header: {
                    Text("Wallpaper")
                } footer: {
                    Text("iOS doesn't let apps change your wallpaper directly. A Shortcuts automation can do it for you every night.")
                }

                Section("Widgets") {
                    Text("Long-press your Home Screen or Lock Screen, tap Edit → Add Widget, and choose LifeDots.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("LifeDots")
            .onAppear { model.recordScreen() }
            .alert("LifeDots", isPresented: Binding(get: { alertText != nil }, set: { if !$0 { alertText = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertText ?? "")
            }
        }
    }

    /// Shows a sensible default until the user picks their birthday.
    private var birthDate: Binding<Date> {
        Binding(
            get: { model.settings.birthDate ?? Calendar.current.date(byAdding: .year, value: -25, to: Date())! },
            set: { model.settings.birthDate = $0 }
        )
    }

    private func saveToPhotos() {
        let image = DotsRenderer.wallpaper(settings: model.settings, screen: model.screen)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, _ in
            DispatchQueue.main.async {
                alertText = success
                    ? "Saved to Photos. Open it, tap Share → Use as Wallpaper."
                    : "Couldn't save. Allow LifeDots to add photos in Settings → Privacy & Security → Photos."
            }
        })
    }
}

/// Scaled-down Lock Screen showing exactly what the wallpaper will look like.
struct PhonePreview: View {
    let settings: LifeSettings
    let screen: ScreenInfo
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let width: CGFloat = 180
        let height = width * CGFloat(screen.pixelHeight) / CGFloat(screen.pixelWidth)
        let size = CGSize(width: width, height: height)
        let screenPointsWidth = CGFloat(screen.pixelWidth) / CGFloat(screen.scale)

        Image(uiImage: DotsRenderer.image(size: size, scale: displayScale, settings: settings,
                                          showCaption: settings.showCaption,
                                          insets: DotsRenderer.lockScreenInsets(for: size),
                                          unit: width / screenPointsWidth))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.secondary.opacity(0.3)))
            .overlay(alignment: .top) {
                // Stand-in for the Lock Screen clock, to show the space left for it.
                Text(Date(), format: .dateTime.hour().minute())
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(uiColor: settings.theme.palette.text).opacity(0.85))
                    .padding(.top, height * 0.09)
            }
            .accessibilityLabel("Wallpaper preview")
    }
}

struct SetupGuideView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                step(1, "Open **Shortcuts**, go to the **Automation** tab and tap **+**.")
                step(2, "Choose **Time of Day**, set it to just after midnight, **Daily**, and select **Run Immediately**.")
                step(3, "Add the action **Generate LifeDots Wallpaper**.")
                step(4, "Add the action **Set Wallpaper Photo**. Pick the wallpaper to update, and turn off **Show Preview** (and **Crop to Subject**, if shown).")
                step(5, "Tap **Done**. Run the automation once to check it.")
            } footer: {
                Text("From then on your wallpaper moves forward a dot every week by itself. Changes you make in LifeDots are picked up on the next run.")
            }

            Section {
                Button("Open Shortcuts") {
                    if let url = URL(string: "shortcuts://") { openURL(url) }
                }
            }
        }
        .navigationTitle("Automatic updates")
    }

    private func step(_ n: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(n)").font(.headline).monospacedDigit().foregroundStyle(.secondary)
            Text(text)
        }
        .padding(.vertical, 2)
    }
}
