import Foundation

// MARK: - Share Utils

func buildMixShareMessage(
    environmentTitle: String,
    environmentCategory: String,
    masterVolume: Double,
    activeSounds: [(title: String, volume: Double)]
) -> String {
    var lines: [String] = []
    lines.append("🎵 Ses Karışımım")
    lines.append("Ortam: \(environmentTitle) (\(environmentCategory))")
    lines.append("Ana Ses: %\(Int(masterVolume))")
    lines.append("Aktif Sesler:")
    for sound in activeSounds {
        lines.append("  • \(sound.title) %\(Int(sound.volume))")
    }
    lines.append("")
    lines.append("R: Rahatlatıcı Sesler uygulamasıyla oluşturuldu. 🌙")
    return lines.joined(separator: "\n")
}
