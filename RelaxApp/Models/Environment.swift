import Foundation

// MARK: - EnvironmentCategory

enum EnvironmentCategory: String, Codable, CaseIterable {
    case sleep      = "sleep"
    case nature     = "nature"
    case meditation = "meditation"
}

// MARK: - FilterGroup

enum FilterGroup: String, CaseIterable, Identifiable {
    case all        = "Tümü"
    case sleep      = "Uyku"
    case nature     = "Doğa"
    case meditation = "Odak & Meditasyon"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:        return "square.grid.2x2.fill"
        case .sleep:      return "moon.stars.fill"
        case .nature:     return "leaf.fill"
        case .meditation: return "figure.mind.and.body"
        }
    }
}

// MARK: - AppEnvironment

struct AppEnvironment: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let category: EnvironmentCategory
    let filterGroup: FilterGroup
    let imageUrl: String
    let thumbnailUrl: String

    static func == (lhs: AppEnvironment, rhs: AppEnvironment) -> Bool {
        lhs.id == rhs.id
    }

    // Codable için FilterGroup rawValue uyumu
    enum CodingKeys: String, CodingKey {
        case id, title, category, filterGroup, imageUrl, thumbnailUrl
    }

    init(id: String,
         title: String,
         category: EnvironmentCategory,
         filterGroup: FilterGroup,
         imageUrl: String,
         thumbnailUrl: String) {
        self.id           = id
        self.title        = title
        self.category     = category
        self.filterGroup  = filterGroup
        self.imageUrl     = imageUrl
        self.thumbnailUrl = thumbnailUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(String.self,              forKey: .id)
        title        = try c.decode(String.self,              forKey: .title)
        category     = try c.decode(EnvironmentCategory.self, forKey: .category)
        let fgRaw    = try c.decode(String.self,              forKey: .filterGroup)
        filterGroup  = FilterGroup(rawValue: fgRaw) ?? .all
        imageUrl     = try c.decode(String.self,              forKey: .imageUrl)
        thumbnailUrl = try c.decode(String.self,              forKey: .thumbnailUrl)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                forKey: .id)
        try c.encode(title,             forKey: .title)
        try c.encode(category,          forKey: .category)
        try c.encode(filterGroup.rawValue, forKey: .filterGroup)
        try c.encode(imageUrl,          forKey: .imageUrl)
        try c.encode(thumbnailUrl,      forKey: .thumbnailUrl)
    }
}

// MARK: - Environment Catalog

extension AppEnvironment {

    // Unsplash temel URL'leri — tam URL'ler aşağıda tanımlanmıştır.
    // Her ortam için ?w=1000&q=85 (tam) / ?w=300&q=70 (küçük) parametreleri kullanılır.

    static let all: [AppEnvironment] = [

        // ── Uyku ──────────────────────────────────────────────────
        AppEnvironment(
            id: "rainy-window",
            title: "Yağmur",
            category: .sleep,
            filterGroup: .sleep,
            imageUrl: "https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "deep-sleep",
            title: "Derin Uyku",
            category: .sleep,
            filterGroup: .sleep,
            imageUrl: "https://images.unsplash.com/photo-1531353826977-0941b4779a1c?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1531353826977-0941b4779a1c?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "pond-night",
            title: "Gece",
            category: .sleep,
            filterGroup: .sleep,
            imageUrl: "https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "night-sky",
            title: "Yıldızlar",
            category: .sleep,
            filterGroup: .sleep,
            imageUrl: "https://images.unsplash.com/photo-1464802686167-b939a6910659?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1464802686167-b939a6910659?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "cozy-fireplace",
            title: "Şömine",
            category: .sleep,
            filterGroup: .sleep,
            imageUrl: "https://images.unsplash.com/photo-1512552288940-3a300922a275?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1512552288940-3a300922a275?w=300&q=70&fm=jpg"
        ),

        // ── Doğa ──────────────────────────────────────────────────
        AppEnvironment(
            id: "forest",
            title: "Orman",
            category: .nature,
            filterGroup: .nature,
            imageUrl: "https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1448375240586-882707db888b?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "peaceful-creek",
            title: "Dere",
            category: .nature,
            filterGroup: .nature,
            imageUrl: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "summer-night",
            title: "Cırcırlar",
            category: .nature,
            filterGroup: .nature,
            imageUrl: "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "autumn-walk",
            title: "Sonbahar",
            category: .nature,
            filterGroup: .nature,
            imageUrl: "https://images.unsplash.com/photo-1476842634003-7dcca8f832de?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1476842634003-7dcca8f832de?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "ocean",
            title: "Okyanus",
            category: .nature,
            filterGroup: .nature,
            imageUrl: "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=300&q=70&fm=jpg"
        ),

        // ── Meditasyon ────────────────────────────────────────────
        AppEnvironment(
            id: "meditation",
            title: "Meditasyon",
            category: .meditation,
            filterGroup: .meditation,
            imageUrl: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=300&q=70&fm=jpg"
        ),
        AppEnvironment(
            id: "deep-focus",
            title: "Odak",
            category: .meditation,
            filterGroup: .meditation,
            imageUrl: "https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=1000&q=85&fm=jpg",
            thumbnailUrl: "https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=300&q=70&fm=jpg"
        )
    ]

    static func environment(for id: String) -> AppEnvironment? {
        all.first { $0.id == id }
    }

    static func environments(for filter: FilterGroup) -> [AppEnvironment] {
        switch filter {
        case .all:        return all
        case .sleep:      return all.filter { $0.category == .sleep }
        case .nature:     return all.filter { $0.category == .nature }
        case .meditation: return all.filter { $0.category == .meditation }
        }
    }
}
