import SwiftUI

private let cardWidth:  CGFloat = 100
private let cardHeight: CGFloat = 124

// MARK: - EnvironmentCarouselView

struct EnvironmentCarouselView: View {
    @EnvironmentObject var vm: AudioMixerViewModel
    @State private var selectedFilter: FilterGroup = .all

    private var filteredEnvironments: [AppEnvironment] {
        AppEnvironment.environments(for: selectedFilter)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ── Filtre Butonları ──────────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(FilterGroup.allCases) { filter in
                        FilterButton(filter: filter, isSelected: selectedFilter == filter) {
                            withAnimation(.spring(duration: 0.25)) {
                                selectedFilter = filter
                            }
                            triggerSelectionHaptic()
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }

            // ── Ortam Kartları ────────────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filteredEnvironments) { env in
                        EnvironmentCard(
                            env: env,
                            isSelected: vm.selectedEnvironmentId == env.id
                        ) {
                            vm.selectEnvironment(env.id)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 4) // gölge kırpılmasın
            }
        }
    }
}

// MARK: - FilterButton

private struct FilterButton: View {
    let filter: FilterGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11))
                if filter == .all {
                    Text(filter.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundStyle(isSelected ? .white : AppColor.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient.accentButtonGradient)
                    : AnyShapeStyle(AppColor.surface2)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isSelected ? AppColor.accent.opacity(0.4) : Color.white.opacity(0.07),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EnvironmentCard

private struct EnvironmentCard: View {
    let env: AppEnvironment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {

                // 1. Fotoğraf
                AsyncImage(url: URL(string: env.thumbnailUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Color(hex: "#1e293b")
                    default:
                        Color(hex: "#1a2332")
                            .overlay(ProgressView().tint(.white.opacity(0.3)).scaleEffect(0.7))
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

                // 2. Alt gradient — okunurluk
                LinearGradient(
                    stops: [
                        .init(color: .clear,                    location: 0.0),
                        .init(color: .black.opacity(0.35),      location: 0.5),
                        .init(color: .black.opacity(0.70),      location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 3. Ortam adı — alt sol
                Text(env.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .truncationMode(.tail)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 11)

                // 4. Aktif indikatör — sağ üst
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(AppColor.accentLight.opacity(0.85))
                                .frame(width: 7, height: 7)
                                .padding(7)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.30))
                                        .padding(4)
                                )
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            // inner glow seçili kart için — border yok
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        isSelected
                            ? AppColor.accentLight.opacity(0.08)
                            : Color.clear
                    )
            )
            .shadow(color: .black.opacity(0.20), radius: 8, x: 0, y: 4)
            // contentShape: hit-test alanını frame ile sabitler
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // scaleEffect button dışında — hit-test alanını etkilemez
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
