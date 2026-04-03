import Foundation

// MARK: - SoundMixState

struct SoundMixState: Equatable, Codable {
    var isEnabled: Bool
    var volume: Double  // 0–100
}

// MARK: - MixMap

typealias MixMap = [SoundId: SoundMixState]

// MARK: - Default Mixes

func defaultMix(for environment: AppEnvironment) -> MixMap {
    // 1. Tüm sesleri kapalı + default hacimle başlat
    var mix: MixMap = [:]
    for sound in Sound.all {
        mix[sound.id] = SoundMixState(isEnabled: false, volume: sound.defaultVolume)
    }

    // 2. Ortama özgü sesleri override et
    let overrides = mixOverrides[environment.id] ?? [:]
    for (soundId, state) in overrides {
        mix[soundId] = state
    }

    return mix
}

// MARK: - Mix Overrides Table

private let mixOverrides: [String: MixMap] = [

    "rainy-window": [
        .rain:        SoundMixState(isEnabled: true,  volume: 65),
        .thunder:     SoundMixState(isEnabled: true,  volume: 28),
        .wind:        SoundMixState(isEnabled: true,  volume: 22),
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 18)
    ],

    "deep-sleep": [
        .rain:        SoundMixState(isEnabled: true,  volume: 45),
        .whiteNoise:  SoundMixState(isEnabled: true,  volume: 52),
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 22),
        .wind:        SoundMixState(isEnabled: true,  volume: 20)
    ],

    "pond-night": [
        .frogs:       SoundMixState(isEnabled: true,  volume: 52),
        .crickets:    SoundMixState(isEnabled: true,  volume: 40),
        .stream:      SoundMixState(isEnabled: true,  volume: 35),
        .wind:        SoundMixState(isEnabled: true,  volume: 18)
    ],

    "night-sky": [
        .wind:        SoundMixState(isEnabled: true,  volume: 28),
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 38),
        .whiteNoise:  SoundMixState(isEnabled: true,  volume: 25),
        .rain:        SoundMixState(isEnabled: true,  volume: 20)
    ],

    "cozy-fireplace": [
        .fire:        SoundMixState(isEnabled: true,  volume: 68),
        .rain:        SoundMixState(isEnabled: true,  volume: 22),
        .wind:        SoundMixState(isEnabled: true,  volume: 15)
    ],

    "forest": [
        .birds:       SoundMixState(isEnabled: true,  volume: 58),
        .leaves:      SoundMixState(isEnabled: true,  volume: 45),
        .stream:      SoundMixState(isEnabled: true,  volume: 38),
        .wind:        SoundMixState(isEnabled: true,  volume: 25)
    ],

    "peaceful-creek": [
        .stream:      SoundMixState(isEnabled: true,  volume: 72),
        .birds:       SoundMixState(isEnabled: true,  volume: 35),
        .leaves:      SoundMixState(isEnabled: true,  volume: 28),
        .frogs:       SoundMixState(isEnabled: true,  volume: 20)
    ],

    "summer-night": [
        .crickets:    SoundMixState(isEnabled: true,  volume: 62),
        .frogs:       SoundMixState(isEnabled: true,  volume: 40),
        .wind:        SoundMixState(isEnabled: true,  volume: 22),
        .stream:      SoundMixState(isEnabled: true,  volume: 25)
    ],

    "autumn-walk": [
        .leaves:      SoundMixState(isEnabled: true,  volume: 65),
        .wind:        SoundMixState(isEnabled: true,  volume: 40),
        .birds:       SoundMixState(isEnabled: true,  volume: 25),
        .rain:        SoundMixState(isEnabled: true,  volume: 18)
    ],

    "ocean": [
        .waves:       SoundMixState(isEnabled: true,  volume: 75),
        .wind:        SoundMixState(isEnabled: true,  volume: 35)
        // Not: "seagulls" SoundId'de yok; waves ana ses
    ],

    "meditation": [
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 58),
        .brownNoise:  SoundMixState(isEnabled: true,  volume: 35),
        .stream:      SoundMixState(isEnabled: true,  volume: 22)
    ],

    "deep-focus": [
        .brownNoise:  SoundMixState(isEnabled: true,  volume: 62),
        .whiteNoise:  SoundMixState(isEnabled: true,  volume: 28),
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 20)
    ]
]

// MARK: - Helpers

extension MixMap {
    /// Etkin (isEnabled == true) ses sayısı
    var activeCount: Int {
        values.filter { $0.isEnabled }.count
    }

    /// Belirli bir ses için state; yoksa kapalı + default
    func state(for id: SoundId) -> SoundMixState {
        self[id] ?? SoundMixState(isEnabled: false,
                                  volume: Sound.sound(for: id).defaultVolume)
    }
}
