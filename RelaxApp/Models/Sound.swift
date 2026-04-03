import Foundation

// MARK: - SoundId

enum SoundId: String, CaseIterable, Codable, Hashable {
    case rain          = "rain"
    case thunder       = "thunder"
    case wind          = "wind"
    case stream        = "stream"
    case waves         = "waves"
    case birds         = "birds"
    case crickets      = "crickets"
    case frogs         = "frogs"
    case leaves        = "leaves"
    case fire          = "fire"
    case whiteNoise    = "white-noise"
    case brownNoise    = "brown-noise"
    case tibetanBowl   = "tibetan-bowl"
}

// MARK: - Sound

struct Sound: Identifiable, Equatable {
    let id: SoundId
    let title: String
    let icon: String
    let defaultVolume: Double
    var audioFileName: String

    static func == (lhs: Sound, rhs: Sound) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sound Catalog

extension Sound {
    static let all: [Sound] = [
        Sound(
            id: .rain,
            title: "Yağmur",
            icon: "cloud.rain.fill",
            defaultVolume: 55,
            audioFileName: "rain.wav"
        ),
        Sound(
            id: .thunder,
            title: "Gök Gürültüsü",
            icon: "cloud.bolt.fill",
            defaultVolume: 30,
            audioFileName: "thunder.wav"
        ),
        Sound(
            id: .wind,
            title: "Rüzgar",
            icon: "wind",
            defaultVolume: 35,
            audioFileName: "wind.wav"
        ),
        Sound(
            id: .stream,
            title: "Dere",
            icon: "water.waves",
            defaultVolume: 45,
            audioFileName: "stream.wav"
        ),
        Sound(
            id: .waves,
            title: "Dalgalar",
            icon: "waveform",
            defaultVolume: 50,
            audioFileName: "waves.wav"
        ),
        Sound(
            id: .birds,
            title: "Kuşlar",
            icon: "bird.fill",
            defaultVolume: 40,
            audioFileName: "birds.wav"
        ),
        Sound(
            id: .crickets,
            title: "Cırcırböcekleri",
            icon: "ant.fill",
            defaultVolume: 35,
            audioFileName: "crickets.wav"
        ),
        Sound(
            id: .frogs,
            title: "Kurbağalar",
            icon: "allergens",
            defaultVolume: 30,
            audioFileName: "frogs.wav"
        ),
        Sound(
            id: .leaves,
            title: "Yapraklar",
            icon: "leaf.fill",
            defaultVolume: 25,
            audioFileName: "leaves.wav"
        ),
        Sound(
            id: .fire,
            title: "Ateş",
            icon: "flame.fill",
            defaultVolume: 50,
            audioFileName: "fire.wav"
        ),
        Sound(
            id: .whiteNoise,
            title: "Beyaz Gürültü",
            icon: "waveform.path",
            defaultVolume: 40,
            audioFileName: "white-noise.wav"
        ),
        Sound(
            id: .brownNoise,
            title: "Kahverengi Gürültü",
            icon: "waveform.path.ecg",
            defaultVolume: 40,
            audioFileName: "brown-noise.wav"
        ),
        Sound(
            id: .tibetanBowl,
            title: "Tibet Tası",
            icon: "music.note",
            defaultVolume: 18,
            audioFileName: "tibetan-bowl.wav"
        )
    ]

    static func sound(for id: SoundId) -> Sound {
        all.first { $0.id == id } ?? all[0]
    }
}
