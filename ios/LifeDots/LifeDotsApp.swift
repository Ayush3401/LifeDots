import SwiftUI
import UIKit
import WidgetKit

@main
struct LifeDotsApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: LifeSettings {
        didSet {
            guard settings != oldValue else { return }
            SharedStore.save(settings)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published private(set) var screen: ScreenInfo

    init() {
        settings = SharedStore.loadSettings()
        screen = SharedStore.loadScreen()
    }

    /// Records this iPhone's screen so the Shortcuts action renders at the right size.
    func recordScreen() {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        let px = scene.screen.nativeBounds.size
        let info = ScreenInfo(pixelWidth: Int(min(px.width, px.height)),
                              pixelHeight: Int(max(px.width, px.height)),
                              scale: Double(scene.screen.nativeScale))
        if info != screen {
            screen = info
            SharedStore.save(info)
        }
    }
}
