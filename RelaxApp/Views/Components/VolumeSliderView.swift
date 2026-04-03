import SwiftUI

// MARK: - VolumeSliderView

struct VolumeSliderView: View {
    @Binding var value: Double
    var isActive: Bool  = true
    var isSmall: Bool   = false
    var showLabel: Bool = false

    private var trackHeight:  CGFloat { isSmall ? 4 : 6 }
    private var thumbSize:    CGFloat { isSmall ? 12 : 18 }

    private var filledColor: some ShapeStyle {
        isActive
            ? AnyShapeStyle(LinearGradient(
                colors: [AppColor.accent, AppColor.accentLight],
                startPoint: .leading,
                endPoint: .trailing
              ))
            : AnyShapeStyle(Color.white.opacity(0.30))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if showLabel {
                Text("\(Int(value))%")
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
            }

            GeometryReader { geo in
                let width = geo.size.width
                let filled = CGFloat(value / 100.0) * width

                ZStack(alignment: .leading) {
                    // Track arka planı
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .frame(height: trackHeight)

                    // Dolu kısım
                    Capsule()
                        .fill(filledColor)
                        .frame(width: max(0, filled), height: trackHeight)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive ? AppColor.accent : Color.white.opacity(0.3),
                                    lineWidth: isSmall ? 1.5 : 2
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                        .offset(x: max(0, min(filled - thumbSize / 2, width - thumbSize)))
                }
                .frame(height: thumbSize)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let raw = drag.location.x / width * 100
                            value = raw.clamped(to: 0...100)
                        }
                )
            }
            .frame(height: thumbSize)
        }
    }
}
