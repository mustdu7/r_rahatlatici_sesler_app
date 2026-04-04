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
        .rain:        SoundMixState(isEnabled: true,  volume: 55),
        .thunder:     SoundMixState(isEnabled: true,  volume: 24),
        .wind:        SoundMixState(isEnabled: true,  volume: 18),
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 15)
    ],

    "deep-sleep": [
        .rain:        SoundMixState(isEnabled: true,  volume: 38),
        .whiteNoise:  SoundMixState(isEnabled: true,  volume: 44),
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 18),
        .wind:        SoundMixState(isEnabled: true,  volume: 17)
    ],

    "pond-night": [
        .frogs:       SoundMixState(isEnabled: true,  volume: 44),
        .crickets:    SoundMixState(isEnabled: true,  volume: 34),
        .stream:      SoundMixState(isEnabled: true,  volume: 30),
        .wind:        SoundMixState(isEnabled: true,  volume: 15)
    ],

    "night-sky": [
        .wind:        SoundMixState(isEnabled: true,  volume: 24),
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 32),
        .whiteNoise:  SoundMixState(isEnabled: true,  volume: 21),
        .rain:        SoundMixState(isEnabled: true,  volume: 17)
    ],

    "cozy-fireplace": [
        .fire:        SoundMixState(isEnabled: true,  volume: 58),
        .rain:        SoundMixState(isEnabled: true,  volume: 18),
        .wind:        SoundMixState(isEnabled: true,  volume: 13)
    ],

    "forest": [
        .birds:       SoundMixState(isEnabled: true,  volume: 49),
        .leaves:      SoundMixState(isEnabled: true,  volume: 38),
        .stream:      SoundMixState(isEnabled: true,  volume: 32),
        .wind:        SoundMixState(isEnabled: true,  volume: 21)
    ],

    "peaceful-creek": [
        .stream:      SoundMixState(isEnabled: true,  volume: 61),
        .birds:       SoundMixState(isEnabled: true,  volume: 30),
        .leaves:      SoundMixState(isEnabled: true,  volume: 24),
        .frogs:       SoundMixState(isEnabled: true,  volume: 17)
    ],

    "summer-night": [
        .crickets:    SoundMixState(isEnabled: true,  volume: 53),
        .frogs:       SoundMixState(isEnabled: true,  volume: 34),
        .wind:        SoundMixState(isEnabled: true,  volume: 18),
        .stream:      SoundMixState(isEnabled: true,  volume: 21)
    ],

    "autumn-walk": [
        .leaves:      SoundMixState(isEnabled: true,  volume: 55),
        .wind:        SoundMixState(isEnabled: true,  volume: 34),
        .birds:       SoundMixState(isEnabled: true,  volume: 21),
        .rain:        SoundMixState(isEnabled: true,  volume: 15)
    ],

    "ocean": [
        .waves:       SoundMixState(isEnabled: true,  volume: 64),
        .wind:        SoundMixState(isEnabled: true,  volume: 30)
        // Not: "seagulls" SoundId'de yok; waves ana ses
    ],

    "meditation": [
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 49),
        .brownNoise:  SoundMixState(isEnabled: true,  volume: 30),
        .stream:      SoundMixState(isEnabled: true,  volume: 18)
    ],

    "deep-focus": [
        .brownNoise:  SoundMixState(isEnabled: true,  volume: 53),
        .whiteNoise:  SoundMixState(isEnabled: true,  volume: 24),
        .tibetanBowl: SoundMixState(isEnabled: true,  volume: 17)
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
