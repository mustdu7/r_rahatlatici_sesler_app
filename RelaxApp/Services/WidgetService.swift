import Foundation
import WidgetKit

// MARK: - WidgetService

class WidgetService {

    static let appGroupId = "group.com.must.rrahatlaticisesler"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    // MARK: - Keys

    private enum Key {
        static let favorite     = "widget.favorite"
        static let timerEndDate = "widget.timerEndDate"
    }

    // MARK: - FavoriteData

    struct FavoriteData: Codable {
        let environmentId: String
        let environmentTitle: String
    }

    // MARK: - Favori Kaydet / Yükle

    static func saveFavorite(_ env: AppEnvironment) {
        let data = FavoriteData(
            environmentId: env.id,
            environmentTitle: env.title
        )
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        sharedDefaults?.set(encoded, forKey: Key.favorite)
        reloadWidgetTimeline()
    }

    static func loadFavorite() -> FavoriteData? {
        guard let data = sharedDefaults?.data(forKey: Key.favorite) else { return nil }
        return try? JSONDecoder().decode(FavoriteData.self, from: data)
    }

    // MARK: - Timer Tarihi Kaydet / Yükle

    static func saveTimerEndDate(_ date: Date?) {
        if let date {
            sharedDefaults?.set(date.timeIntervalSince1970, forKey: Key.timerEndDate)
        } else {
            sharedDefaults?.removeObject(forKey: Key.timerEndDate)
        }
        reloadWidgetTimeline()
    }

    static func loadTimerEndDate() -> Date? {
        let ts = sharedDefaults?.double(forKey: Key.timerEndDate) ?? 0
        guard ts > 0 else { return nil }
        let date = Date(timeIntervalSince1970: ts)
        return date > Date() ? date : nil  // süresi geçmişse nil döndür
    }

    // MARK: - Widget Timeline Yenile

    static func reloadWidgetTimeline() {
        WidgetCenter.shared.reloadTimelines(ofKind: "RelaxWidget")
    }
}
