import SwiftUI

// MARK: - PlayerCardView

struct PlayerCardView: View {
    @EnvironmentObject var vm: AudioMixerViewModel

    var body: some View {
        VStack(spacing: 10) {

            // ── Üst Satır: Başlık + Mute ──────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.activeEnvironment.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)

                    Text("\(vm.activeSoundsCount) ses aktif")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()

                Button {
                    vm.setMute(!vm.isMuted)
                    triggerSelectionHaptic()
                } label: {
                    Image(systemName: vm.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(vm.isMuted ? AppColor.danger : AppColor.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }

            // ── Orta: Play + Reset ────────────────────────────────
            HStack(spacing: 20) {
                Spacer()

                // Reset
                Button { vm.resetMix() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppColor.surface2)
                        .clipShape(Circle())
                }

                // Play / Pause
                Button { vm.togglePlay() } label: {
                    ZStack {
                        Circle()
                            .fill(
                                vm.isPlaying
                                    ? LinearGradient.accentPlayGradient
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                      )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(
                                color: vm.isPlaying ? AppColor.accent.opacity(0.4) : .black.opacity(0.35),
                                radius: vm.isPlaying ? 12 : 6, x: 0, y: 3
                            )

                        if vm.isAudioReady {
                            Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: vm.isPlaying ? 0 : 1)
                        } else {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(!vm.isAudioReady)
                .animation(.spring(duration: 0.25), value: vm.isPlaying)
                .animation(.easeInOut(duration: 0.2), value: vm.isAudioReady)

                Color.clear.frame(width: 32, height: 32) // simetri

                Spacer()
            }

            // ── Alt: Master Volume ────────────────────────────────
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColor.textSecondary)
                    Text("Ana Ses")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Text("\(Int(vm.masterVolume))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColor.textSecondary)
                }
                VolumeSliderView(
                    value: Binding(
                        get: { vm.masterVolume },
                        set: { vm.setMasterVolume($0) }
                    ),
                    isActive: vm.isPlaying,
                    isSmall: true,
                    showLabel: false
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(
                    vm.isPlaying ? AppColor.accent.opacity(0.22) : Color.white.opacity(0.09),
                    lineWidth: 1
                )
        )
        .shadow(
            color: vm.isPlaying ? AppColor.accent.opacity(0.12) : .black.opacity(0.25),
            radius: vm.isPlaying ? 16 : 8, x: 0, y: 3
        )
        .animation(.easeInOut(duration: 0.3), value: vm.isPlaying)
    }
}
