import SwiftUI

// MARK: - GlowLayer

struct GlowLayer {
    var color: Color
    var opacity: Double
    var width: CGFloat
    var height: CGFloat
    var xOffset: CGFloat
    var yOffset: CGFloat
    var blurRadius: CGFloat
}

// MARK: - AmbientTheme

struct AmbientTheme {
    let environmentId: String
    let accentGradientColors: [Color]
    let imageOpacity: Double
    let overlayGradient: [Color]
    let safeAreaColor: Color
    let glowLayers: [GlowLayer]
}

// MARK: - Theme Catalog

extension AmbientTheme {

    static let all: [AmbientTheme] = [
        rainyWindowTheme,
        deepSleepTheme,
        pondNightTheme,
        nightSkyTheme,
        cozyFireplaceTheme,
        forestTheme,
        peacefulCreekTheme,
        summerNightTheme,
        autumnWalkTheme,
        oceanTheme,
        meditationTheme,
        deepFocusTheme
    ]

    static func theme(for environmentId: String) -> AmbientTheme {
        all.first { $0.environmentId == environmentId } ?? rainyWindowTheme
    }

    // ── Yağmurlu Pencere ─────────────────────────────────────────
    static let rainyWindowTheme = AmbientTheme(
        environmentId: "rainy-window",
        accentGradientColors: [
            Color.blue.opacity(0.30),
            Color.cyan.opacity(0.15)
        ],
        imageOpacity: 0.40,
        overlayGradient: [
            Color(hex: "#0a0e1a").opacity(0.70),
            Color(hex: "#0a1628").opacity(0.50),
            Color(hex: "#0d1f3c").opacity(0.30),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#080c18"),
        glowLayers: [
            GlowLayer(color: .blue,   opacity: 0.18, width: 280, height: 180,
                      xOffset: -80, yOffset: -120, blurRadius: 80),
            GlowLayer(color: .cyan,   opacity: 0.10, width: 200, height: 140,
                      xOffset:  60, yOffset: -60,  blurRadius: 60)
        ]
    )

    // ── Derin Uyku ───────────────────────────────────────────────
    static let deepSleepTheme = AmbientTheme(
        environmentId: "deep-sleep",
        accentGradientColors: [
            Color(hex: "#1e1b4b").opacity(0.50),
            Color(hex: "#312e81").opacity(0.25)
        ],
        imageOpacity: 0.30,
        overlayGradient: [
            Color(hex: "#05060f").opacity(0.85),
            Color(hex: "#0e0b2e").opacity(0.60),
            Color(hex: "#1a1640").opacity(0.30),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#05060f"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#6366f1"), opacity: 0.20, width: 300, height: 200,
                      xOffset: -60, yOffset: -130, blurRadius: 90),
            GlowLayer(color: Color(hex: "#a78bfa"), opacity: 0.10, width: 180, height: 120,
                      xOffset:  80, yOffset: -40,  blurRadius: 55)
        ]
    )

    // ── Gölet Gecesi ─────────────────────────────────────────────
    static let pondNightTheme = AmbientTheme(
        environmentId: "pond-night",
        accentGradientColors: [
            Color(hex: "#0f2027").opacity(0.60),
            Color(hex: "#203a43").opacity(0.35),
            Color(hex: "#2c5364").opacity(0.20)
        ],
        imageOpacity: 0.45,
        overlayGradient: [
            Color(hex: "#060d12").opacity(0.80),
            Color(hex: "#0b1a22").opacity(0.55),
            Color(hex: "#0f2535").opacity(0.25),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#060d12"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#0ea5e9"), opacity: 0.15, width: 260, height: 160,
                      xOffset: -90, yOffset: -100, blurRadius: 70),
            GlowLayer(color: Color(hex: "#22d3ee"), opacity: 0.08, width: 160, height: 100,
                      xOffset:  70, yOffset:  20,  blurRadius: 50)
        ]
    )

    // ── Gece Gökyüzü ─────────────────────────────────────────────
    static let nightSkyTheme = AmbientTheme(
        environmentId: "night-sky",
        accentGradientColors: [
            Color(hex: "#020617").opacity(0.70),
            Color(hex: "#0f172a").opacity(0.40)
        ],
        imageOpacity: 0.55,
        overlayGradient: [
            Color(hex: "#020617").opacity(0.75),
            Color(hex: "#0f172a").opacity(0.50),
            Color(hex: "#1e293b").opacity(0.25),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#020617"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#818cf8"), opacity: 0.22, width: 320, height: 220,
                      xOffset:   0, yOffset: -150, blurRadius: 100),
            GlowLayer(color: Color(hex: "#c084fc"), opacity: 0.10, width: 200, height: 120,
                      xOffset:  90, yOffset: -30,  blurRadius: 60),
            GlowLayer(color: Color(hex: "#38bdf8"), opacity: 0.07, width: 150, height: 80,
                      xOffset: -70, yOffset:  60,  blurRadius: 45)
        ]
    )

    // ── Sıcak Şömine ─────────────────────────────────────────────
    static let cozyFireplaceTheme = AmbientTheme(
        environmentId: "cozy-fireplace",
        accentGradientColors: [
            Color(hex: "#7c2d12").opacity(0.45),
            Color(hex: "#ea580c").opacity(0.20)
        ],
        imageOpacity: 0.45,
        overlayGradient: [
            Color(hex: "#0c0805").opacity(0.80),
            Color(hex: "#1c0d05").opacity(0.55),
            Color(hex: "#2d1505").opacity(0.25),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#0c0805"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#f97316"), opacity: 0.25, width: 280, height: 200,
                      xOffset:  20, yOffset: -80,  blurRadius: 85),
            GlowLayer(color: Color(hex: "#fbbf24"), opacity: 0.12, width: 180, height: 120,
                      xOffset: -50, yOffset:  40,  blurRadius: 55)
        ]
    )

    // ── Orman ────────────────────────────────────────────────────
    static let forestTheme = AmbientTheme(
        environmentId: "forest",
        accentGradientColors: [
            Color(hex: "#14532d").opacity(0.40),
            Color(hex: "#166534").opacity(0.20)
        ],
        imageOpacity: 0.50,
        overlayGradient: [
            Color(hex: "#030a05").opacity(0.75),
            Color(hex: "#071a0b").opacity(0.50),
            Color(hex: "#0d2b12").opacity(0.25),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#030a05"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#22c55e"), opacity: 0.18, width: 260, height: 180,
                      xOffset: -70, yOffset: -110, blurRadius: 75),
            GlowLayer(color: Color(hex: "#86efac"), opacity: 0.08, width: 180, height: 100,
                      xOffset:  60, yOffset:  30,  blurRadius: 50)
        ]
    )

    // ── Huzurlu Dere ─────────────────────────────────────────────
    static let peacefulCreekTheme = AmbientTheme(
        environmentId: "peaceful-creek",
        accentGradientColors: [
            Color(hex: "#0d4f4a").opacity(0.45),
            Color(hex: "#0f766e").opacity(0.22)
        ],
        imageOpacity: 0.50,
        overlayGradient: [
            Color(hex: "#020c0b").opacity(0.78),
            Color(hex: "#061615").opacity(0.52),
            Color(hex: "#0a2422").opacity(0.26),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#020c0b"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#14b8a6"), opacity: 0.20, width: 270, height: 170,
                      xOffset: -60, yOffset: -100, blurRadius: 72),
            GlowLayer(color: Color(hex: "#5eead4"), opacity: 0.09, width: 160, height: 100,
                      xOffset:  80, yOffset:  20,  blurRadius: 48)
        ]
    )

    // ── Yaz Gecesi ───────────────────────────────────────────────
    static let summerNightTheme = AmbientTheme(
        environmentId: "summer-night",
        accentGradientColors: [
            Color(hex: "#1a3d1f").opacity(0.45),
            Color(hex: "#166534").opacity(0.20)
        ],
        imageOpacity: 0.42,
        overlayGradient: [
            Color(hex: "#040b06").opacity(0.82),
            Color(hex: "#091409").opacity(0.55),
            Color(hex: "#0f2210").opacity(0.28),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#040b06"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#4ade80"), opacity: 0.15, width: 240, height: 160,
                      xOffset: -80, yOffset: -90,  blurRadius: 65),
            GlowLayer(color: Color(hex: "#fde68a"), opacity: 0.08, width: 150, height: 90,
                      xOffset:  70, yOffset:  50,  blurRadius: 45)
        ]
    )

    // ── Sonbahar Yürüyüşü ────────────────────────────────────────
    static let autumnWalkTheme = AmbientTheme(
        environmentId: "autumn-walk",
        accentGradientColors: [
            Color(hex: "#78350f").opacity(0.40),
            Color(hex: "#d97706").opacity(0.18)
        ],
        imageOpacity: 0.48,
        overlayGradient: [
            Color(hex: "#0c0804").opacity(0.78),
            Color(hex: "#1a1008").opacity(0.52),
            Color(hex: "#2a1c0e").opacity(0.26),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#0c0804"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#f59e0b"), opacity: 0.20, width: 260, height: 170,
                      xOffset: -65, yOffset: -95,  blurRadius: 72),
            GlowLayer(color: Color(hex: "#fb923c"), opacity: 0.10, width: 170, height: 110,
                      xOffset:  75, yOffset:  35,  blurRadius: 50)
        ]
    )

    // ── Okyanus ──────────────────────────────────────────────────
    static let oceanTheme = AmbientTheme(
        environmentId: "ocean",
        accentGradientColors: [
            Color(hex: "#0c4a6e").opacity(0.45),
            Color(hex: "#0369a1").opacity(0.22)
        ],
        imageOpacity: 0.52,
        overlayGradient: [
            Color(hex: "#020b12").opacity(0.76),
            Color(hex: "#071828").opacity(0.50),
            Color(hex: "#0c2a40").opacity(0.25),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#020b12"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#0284c7"), opacity: 0.22, width: 300, height: 190,
                      xOffset: -55, yOffset: -115, blurRadius: 80),
            GlowLayer(color: Color(hex: "#38bdf8"), opacity: 0.10, width: 190, height: 120,
                      xOffset:  75, yOffset:  25,  blurRadius: 55)
        ]
    )

    // ── Meditasyon ───────────────────────────────────────────────
    static let meditationTheme = AmbientTheme(
        environmentId: "meditation",
        accentGradientColors: [
            Color(hex: "#4c1d95").opacity(0.40),
            Color(hex: "#7c3aed").opacity(0.20)
        ],
        imageOpacity: 0.35,
        overlayGradient: [
            Color(hex: "#08030f").opacity(0.82),
            Color(hex: "#130824").opacity(0.55),
            Color(hex: "#1e1038").opacity(0.28),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#08030f"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#a855f7"), opacity: 0.22, width: 290, height: 190,
                      xOffset:   0, yOffset: -120, blurRadius: 85),
            GlowLayer(color: Color(hex: "#f0abfc"), opacity: 0.10, width: 180, height: 110,
                      xOffset:  70, yOffset:  20,  blurRadius: 55),
            GlowLayer(color: Color(hex: "#fcd34d"), opacity: 0.06, width: 130, height: 80,
                      xOffset: -80, yOffset:  60,  blurRadius: 40)
        ]
    )

    // ── Derin Odak ───────────────────────────────────────────────
    static let deepFocusTheme = AmbientTheme(
        environmentId: "deep-focus",
        accentGradientColors: [
            Color(hex: "#1e1b4b").opacity(0.50),
            Color(hex: "#3730a3").opacity(0.25),
            Color(hex: "#6d28d9").opacity(0.12)
        ],
        imageOpacity: 0.32,
        overlayGradient: [
            Color(hex: "#06050f").opacity(0.85),
            Color(hex: "#0e0c28").opacity(0.58),
            Color(hex: "#181440").opacity(0.30),
            Color.clear
        ],
        safeAreaColor: Color(hex: "#06050f"),
        glowLayers: [
            GlowLayer(color: Color(hex: "#6366f1"), opacity: 0.20, width: 280, height: 180,
                      xOffset: -60, yOffset: -130, blurRadius: 82),
            GlowLayer(color: Color(hex: "#c084fc"), opacity: 0.10, width: 170, height: 105,
                      xOffset:  80, yOffset: -20,  blurRadius: 52),
            GlowLayer(color: Color(hex: "#818cf8"), opacity: 0.07, width: 120, height: 70,
                      xOffset: -40, yOffset:  80,  blurRadius: 38)
        ]
    )
}
