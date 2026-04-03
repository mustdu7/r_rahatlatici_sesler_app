import Foundation

// MARK: - TimerOption

struct TimerOption: Identifiable {
    let id: String
    let label: String
    let minutes: Int
}

// MARK: - Preset Options

let timerOptions: [TimerOption] = [
    TimerOption(id: "5dk",    label: "5 dk",    minutes: 5),
    TimerOption(id: "15dk",   label: "15 dk",   minutes: 15),
    TimerOption(id: "30dk",   label: "30 dk",   minutes: 30),
    TimerOption(id: "45dk",   label: "45 dk",   minutes: 45),
    TimerOption(id: "1saat",  label: "1 saat",  minutes: 60),
    TimerOption(id: "ozel",   label: "Özel",    minutes: 0)
]

// MARK: - Format Helpers

/// 5 → "5 dk" | 60 → "1 saat" | 90 → "1 saat 30 dk"
func formatMinutesLabel(_ minutes: Int) -> String {
    guard minutes > 0 else { return "Özel" }
    let hours = minutes / 60
    let mins  = minutes % 60
    switch (hours, mins) {
    case (0, let m):       return "\(m) dk"
    case (let h, 0):       return "\(h) saat"
    case (let h, let m):   return "\(h) saat \(m) dk"
    }
}

/// 30 → "30sn" | 61 → "1dk 1sn" | 3661 → "1s 1dk 1sn"
func formatRemainingDuration(_ seconds: Int) -> String {
    guard seconds > 0 else { return "0sn" }
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60

    var parts: [String] = []
    if h > 0 { parts.append("\(h)sa") }
    if m > 0 { parts.append("\(m)dk") }
    if s > 0 || parts.isEmpty { parts.append("\(s)sn") }
    return parts.joined(separator: " ")
}
