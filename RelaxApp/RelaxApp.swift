import SwiftUI
import AVFoundation

// MARK: - RelaxApp

@main
struct RelaxApp: App {
    @StateObject private var vm = AudioMixerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .onOpenURL { url in
                    ShortcutsService.handle(url: url, using: vm)
                }
                .task {
                    await NotificationService.shared.requestPermission()
                    await MainActor.run {
                        AudioIntentBridge.shared.register(vm)
                    }
                }
        }
    }
}
