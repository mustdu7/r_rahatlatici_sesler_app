import SwiftUI

// MARK: - HeaderView

struct HeaderView: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))
                .symbolRenderingMode(.hierarchical)

            Text("R: Rahatlatıcı Sesler")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 6)
    }
}
