import WidgetKit
import SwiftUI

// MARK: - RelaxEntry

struct RelaxEntry: TimelineEntry {
    let date: Date
    let timerEndDate: Date?
    let favorite: WidgetService.FavoriteData?
}

// MARK: - RelaxWidgetProvider

struct RelaxWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> RelaxEntry {
        RelaxEntry(date: .now, timerEndDate: nil, favorite: nil)
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (RelaxEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<RelaxEntry>) -> Void) {
        let entry = currentEntry()
        let refreshDate: Date
        if let end = entry.timerEndDate, end > .now {
            refreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: .now) ?? .now
        } else {
            refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        }
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func currentEntry() -> RelaxEntry {
        RelaxEntry(
            date: .now,
            timerEndDate: WidgetService.loadTimerEndDate(),
            favorite: WidgetService.loadFavorite()
        )
    }
}

// MARK: - AppLogoView

private struct AppLogoView: View {
    let size: CGFloat

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

// MARK: - RelaxWidgetEntryView

struct RelaxWidgetEntryView: View {
    let entry: RelaxEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall: SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default: SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - SmallWidgetView

private struct SmallWidgetView: View {
    let entry: RelaxEntry

    private var deepLinkURL: URL {
        if let fav = entry.favorite,
           let url = URL(string: "relax://environment/\(fav.environmentId)") { return url }
        return URL(string: "relax://play")!
    }

    var body: some View {
        VStack(spacing: 5) {
            if let end = entry.timerEndDate, end > .now {
                AppLogoView(size: 30)
                Text(timerLabel(end: end))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#4ade80"))
                Text("sonra kapanacak")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.55))
            } else if let fav = entry.favorite {
                AppLogoView(size: 30)
                Text(fav.environmentTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            } else {
                AppLogoView(size: 30)
                Text("Rahatla")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .padding(10)
        .widgetURL(deepLinkURL)
    }

    private func timerLabel(end: Date) -> String {
        let remaining = max(0, Int(end.timeIntervalSinceNow))
        let m = remaining / 60
        let s = remaining % 60
        return m > 0 ? "\(m)dk \(s)sn" : "\(s)sn"
    }
}

// MARK: - MediumWidgetView

private struct MediumWidgetView: View {
    let entry: RelaxEntry

    var body: some View {
        HStack(spacing: 0) {

            // ── Sol: Favori ortam ─────────────────────────────────
            Link(destination: {
                if let fav = entry.favorite,
                   let url = URL(string: "relax://environment/\(fav.environmentId)") { return url }
                return URL(string: "relax://play")!
            }()) {
                VStack(alignment: .leading, spacing: 6) {
                    AppLogoView(size: 30)

                    Spacer(minLength: 0)

                    Text(entry.favorite?.environmentTitle ?? "Rahatlatıcı Sesler")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text("Başlat")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "#4ade80"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#22c55e").opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }

            // ── Ayraç ─────────────────────────────────────────────
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 0.5)
                .padding(.vertical, 10)

            // ── Sağ: Timer veya hazır ─────────────────────────────
            VStack(spacing: 4) {
                if let end = entry.timerEndDate, end > .now {
                    let remaining = max(0, Int(end.timeIntervalSinceNow))
                    let m = remaining / 60
                    let s = remaining % 60
                    Image(systemName: "timer")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#fbbf24"))
                    Text(m > 0 ? "\(m)dk \(s)sn" : "\(s)sn")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#fbbf24"))
                    Text("sonra kapanacak")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#4ade80"))
                    Text("Hazır")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Dinlemeye başla")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - RelaxWidget (Entry Point)

@main
struct RelaxWidget: Widget {
    let kind = "RelaxWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: RelaxWidgetProvider()) { entry in
            RelaxWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(hex: "#0a1628")
                }
        }
        .configurationDisplayName("R: Rahatlatıcı Sesler")
        .description("Seslerini kontrol et ve zamanlayıcıyı takip et.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Color Helper (Widget hedefi için kopya)

private extension Color {
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        let scanner = Scanner(string: cleaned)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - WidgetService stub (Widget hedefi için)

enum WidgetService {
    struct FavoriteData: Codable {
        let environmentId: String
        let environmentTitle: String
    }

    static let appGroupId = "group.com.must.rrahatlaticisesler"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func loadFavorite() -> FavoriteData? {
        guard let data = sharedDefaults?.data(forKey: "widget.favorite") else { return nil }
        return try? JSONDecoder().decode(FavoriteData.self, from: data)
    }

    static func loadTimerEndDate() -> Date? {
        let ts = sharedDefaults?.double(forKey: "widget.timerEndDate") ?? 0
        guard ts > 0 else { return nil }
        let date = Date(timeIntervalSince1970: ts)
        return date > Date() ? date : nil
    }
}
