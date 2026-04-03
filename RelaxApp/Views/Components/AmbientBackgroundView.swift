import SwiftUI

// MARK: - AmbientBackgroundView

struct AmbientBackgroundView: View {
    @EnvironmentObject var vm: AudioMixerViewModel

    private var theme: AmbientTheme {
        AmbientTheme.theme(for: vm.selectedEnvironmentId)
    }

    private var env: AppEnvironment {
        vm.activeEnvironment
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. Sabit arka plan rengi
                AppColor.background
                    .ignoresSafeArea()

                // 2. Bulanık küçük resim (arka plan dolgusu)
                AsyncImage(url: URL(string: env.thumbnailUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 24)
                    default:
                        Color.clear
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

                // 3. Net görsel (az bulanık, düşük opaklık)
                AsyncImage(url: URL(string: env.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 6)
                            .opacity(theme.imageOpacity)
                    default:
                        Color.clear
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

                // 4. Overlay gradient (dikey, koyu)
                LinearGradient(
                    colors: theme.overlayGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 5. Accent gradient katmanı
                LinearGradient(
                    colors: theme.accentGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .blendMode(.screen)

                // 6. Glow katmanları
                ForEach(0..<theme.glowLayers.count, id: \.self) { i in
                    let glow = theme.glowLayers[i]
                    Ellipse()
                        .fill(glow.color.opacity(glow.opacity))
                        .frame(width: glow.width, height: glow.height)
                        .offset(x: glow.xOffset, y: glow.yOffset)
                        .blur(radius: glow.blurRadius)
                        .allowsHitTesting(false)
                }

                // 7. Alt derinlik gradyanı
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.30),
                        Color(hex: "#0a0e1a").opacity(0.60)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.7), value: vm.selectedEnvironmentId)
    }
}
