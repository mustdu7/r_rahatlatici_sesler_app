import SwiftUI

// MARK: - SoundMixerGridView

struct SoundMixerGridView: View {
    @EnvironmentObject var vm: AudioMixerViewModel
    @State private var showAll: Bool = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var displayedSounds: [Sound] {
        let sorted = vm.sortedSounds
        return showAll ? sorted : Array(sorted.prefix(9))
    }

    var body: some View {
        VStack(spacing: 12) {
            // Izgara
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(displayedSounds) { sound in
                    SoundCard(sound: sound)
                }
            }

            // Tümünü Gör / Küçült
            if Sound.all.count > 9 {
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        showAll.toggle()
                    }
                    triggerSoftImpactHaptic()
                } label: {
                    HStack(spacing: 6) {
                        Text(showAll ? "Küçült" : "Tümünü Gör")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: showAll ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(AppColor.accent)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - SoundCard

private struct SoundCard: View {
    @EnvironmentObject var vm: AudioMixerViewModel
    let sound: Sound

    private var state: SoundMixState {
        vm.soundMix.state(for: sound.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Üst: İkon + Ad
            HStack(spacing: 6) {
                Image(systemName: sound.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(
                        state.isEnabled
                            ? AppColor.accentLight
                            : AppColor.textSecondary
                    )

                Text(sound.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        state.isEnabled
                            ? AppColor.textPrimary
                            : AppColor.textSecondary.opacity(0.5)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .opacity(state.isEnabled ? 1.0 : 0.5)

            // Alt: Küçük slider
            VolumeSliderView(
                value: Binding(
                    get: { state.volume },
                    set: { vm.setSoundVolume(id: sound.id, volume: $0) }
                ),
                isActive: state.isEnabled,
                isSmall: true,
                showLabel: false
            )
            .opacity(state.isEnabled ? 1.0 : 0.35)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            state.isEnabled
                ? AppColor.accent.opacity(0.12)
                : Color.white.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(
                    state.isEnabled
                        ? AppColor.accent.opacity(0.25)
                        : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            vm.toggleSound(id: sound.id)
        }
        .animation(.easeInOut(duration: 0.2), value: state.isEnabled)
    }
}
