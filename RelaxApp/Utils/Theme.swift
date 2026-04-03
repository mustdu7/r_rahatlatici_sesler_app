import SwiftUI

// MARK: - AppColor

enum AppColor {
    static let background    = Color(hex: "#0a0e1a")
    static let surface1      = Color.white.opacity(0.03)
    static let surface2      = Color.white.opacity(0.07)
    static let textPrimary   = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.62)
    static let accent        = Color(hex: "#22c55e")
    static let accentLight   = Color(hex: "#4ade80")
    static let danger        = Color(hex: "#f87171")
}

// MARK: - AppSpacing

enum AppSpacing {
    static let xs:  Double = 6
    static let sm:  Double = 10
    static let md:  Double = 16
    static let lg:  Double = 20
    static let xl:  Double = 24
    static let xxl: Double = 30
}

// MARK: - AppRadius

enum AppRadius {
    static let sm:   Double = 12
    static let md:   Double = 16
    static let lg:   Double = 20
    static let xl:   Double = 24
    static let pill: Double = 999
}

// MARK: - Color + Hex

extension Color {
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }

        let scanner = Scanner(string: cleaned)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r, g, b, a: Double
        switch cleaned.count {
        case 6:
            r = Double((rgb >> 16) & 0xFF) / 255
            g = Double((rgb >>  8) & 0xFF) / 255
            b = Double( rgb        & 0xFF) / 255
            a = 1.0
        case 8:
            r = Double((rgb >> 24) & 0xFF) / 255
            g = Double((rgb >> 16) & 0xFF) / 255
            b = Double((rgb >>  8) & 0xFF) / 255
            a = Double( rgb        & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - View Modifiers

extension View {
    func sectionTitle() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColor.textPrimary)
    }

    func timerDescription() -> some View {
        self
            .font(.caption)
            .foregroundStyle(AppColor.accentLight)
            .padding(.top, 4)
    }

    func glassCard(cornerRadius: Double = AppRadius.xl) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {
    static var accentPlayGradient: LinearGradient {
        LinearGradient(
            colors: [AppColor.accent, AppColor.accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#16a34a"), Color(hex: "#22c55e")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
