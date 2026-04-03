import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var vm: AudioMixerViewModel

    var body: some View {
        ZStack {
            AmbientBackgroundView()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HeaderView()
                        .padding(.top, 8)

                    PlayerCardView()
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.sm)

                    EnvironmentCarouselView()
                        .padding(.top, AppSpacing.lg)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Ses Karışımı")
                            .sectionTitle()
                            .padding(.top, AppSpacing.lg)

                        SoundMixerGridView()
                            .padding(.top, AppSpacing.sm)

                        TimerSectionView()
                            .padding(.top, AppSpacing.lg)

                        BottomActionsView()
                            .padding(.top, AppSpacing.lg)
                            .padding(.bottom, AppSpacing.xl)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
