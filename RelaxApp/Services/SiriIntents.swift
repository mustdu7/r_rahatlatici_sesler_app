import AppIntents

// MARK: - EnvironmentAppEnum
// AppShortcut phrase'lerinde parametre kullanmak için AppEnum gerekli

enum EnvironmentAppEnum: String, AppEnum {
    case yagmur      = "rainy-window"
    case derinUyku   = "deep-sleep"
    case gece        = "pond-night"
    case yildizlar   = "night-sky"
    case somine      = "cozy-fireplace"
    case orman       = "forest"
    case okyanus     = "ocean"
    case dere        = "stream"
    case circirlar   = "crickets"
    case sonbahar    = "autumn-leaves"
    case meditasyon  = "meditation"
    case odak        = "focus"
    case beyazGurultu = "white-noise"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Ortam"
    static var caseDisplayRepresentations: [EnvironmentAppEnum: DisplayRepresentation] = [
        .yagmur:       "Yağmur",
        .derinUyku:    "Derin Uyku",
        .gece:         "Gece",
        .yildizlar:    "Yıldızlar",
        .somine:       "Şömine",
        .orman:        "Orman",
        .okyanus:      "Okyanus",
        .dere:         "Dere",
        .circirlar:    "Cırcırlar",
        .sonbahar:     "Sonbahar",
        .meditasyon:   "Meditasyon",
        .odak:         "Odak",
        .beyazGurultu: "Beyaz Gürültü"
    ]
}

// MARK: - AppShortcutsProvider

struct RelaxShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlaySoundIntent(),
            phrases: [
                "\(.applicationName) başlat",
                "\(.applicationName)'i başlat",
                "\(.applicationName) seslerini aç"
            ],
            shortTitle: "Başlat",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: PauseSoundIntent(),
            phrases: [
                "\(.applicationName) durdur",
                "\(.applicationName)'i durdur",
                "\(.applicationName) seslerini kapat"
            ],
            shortTitle: "Durdur",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: PlayEnvironmentIntent(),
            phrases: [
                "\(.applicationName)'de \(\.$environment) başlat",
                "\(.applicationName) ile \(\.$environment) çal"
            ],
            shortTitle: "Ortam Başlat",
            systemImageName: "waveform"
        )
    }
}

// MARK: - PlaySoundIntent

struct PlaySoundIntent: AppIntent {
    static var title: LocalizedStringResource = "Sesleri Başlat"
    static var description = IntentDescription("Rahatlatıcı sesleri oynatmaya başlar.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            AudioIntentBridge.shared.play()
        }
        return .result(dialog: "Rahatlatıcı sesler başlatıldı.")
    }
}

// MARK: - PauseSoundIntent

struct PauseSoundIntent: AppIntent {
    static var title: LocalizedStringResource = "Sesleri Durdur"
    static var description = IntentDescription("Rahatlatıcı sesleri duraklatır.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            AudioIntentBridge.shared.pause()
        }
        return .result(dialog: "Sesler durduruldu.")
    }
}

// MARK: - PlayEnvironmentIntent

struct PlayEnvironmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Ortam Seç ve Başlat"
    static var description = IntentDescription("Seçilen ortamı başlatır.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Ortam")
    var environment: EnvironmentAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("'\(\.$environment)' ortamını başlat")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let envId = environment.rawValue
        await MainActor.run {
            AudioIntentBridge.shared.playEnvironment(id: envId)
        }
        return .result(dialog: "\(environment.rawValue) başlatıldı.")
    }
}

// MARK: - AudioIntentBridge

@MainActor
final class AudioIntentBridge {
    static let shared = AudioIntentBridge()
    private weak var viewModel: AudioMixerViewModel?

    func register(_ vm: AudioMixerViewModel) {
        viewModel = vm
    }

    func play()  { viewModel?.play() }
    func pause() { viewModel?.pause() }

    func playEnvironment(id: String) {
        viewModel?.selectEnvironment(id)
        viewModel?.play()
    }
}
