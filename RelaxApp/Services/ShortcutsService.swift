import Foundation

// MARK: - ShortcutsService

struct ShortcutsService {

    @MainActor
    static func handle(url: URL, using vm: AudioMixerViewModel) {
        guard url.scheme == "relax" else { return }

        let host      = url.host ?? ""
        let pathParts = url.pathComponents.filter { $0 != "/" }

        switch host {

        // relax://play
        case "play":
            if pathParts.isEmpty {
                vm.play()
            }
            // relax://play-with-timer/{envId}?minutes={min}
            else if let envId = pathParts.first {
                let minutes = Int(url.queryValue(for: "minutes") ?? "0") ?? 0
                vm.selectEnvironment(envId)
                vm.play()
                if minutes > 0 { vm.setSleepTimer(minutes: minutes) }
            }

        // relax://pause
        case "pause":
            vm.pause()

        // relax://toggle-play
        case "toggle-play":
            vm.togglePlay()

        // relax://environment/{id}
        case "environment":
            if let envId = pathParts.first {
                vm.selectEnvironment(envId)
            }

        // relax://timer/{minutes}
        case "timer":
            if let minStr = pathParts.first, let min = Int(minStr) {
                vm.setSleepTimer(minutes: min)
            }

        // Kısayollar
        case "forest":
            vm.selectEnvironment("forest")
            vm.play()

        case "ocean":
            vm.selectEnvironment("ocean")
            vm.play()

        case "meditation":
            vm.selectEnvironment("meditation")
            vm.play()

        default:
            print("[ShortcutsService] Tanınmayan URL: \(url)")
        }
    }
}

// MARK: - URL Helper

private extension URL {
    func queryValue(for key: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == key }?
            .value
    }
}
