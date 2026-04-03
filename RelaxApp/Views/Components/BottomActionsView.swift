import SwiftUI
import UIKit

// MARK: - BottomActionsView

struct BottomActionsView: View {
    @EnvironmentObject var vm: AudioMixerViewModel
    @State private var showingShareSheet: Bool = false
    @State private var showingAbout: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Paylaş
            ActionButton(
                icon: "square.and.arrow.up",
                label: "Paylaş",
                color: AppColor.textSecondary
            ) {
                showingShareSheet = true
                triggerSoftImpactHaptic()
            }

            // Hakkında
            ActionButton(
                icon: "info.circle",
                label: "Hakkında",
                color: AppColor.textSecondary
            ) {
                showingAbout = true
                triggerSoftImpactHaptic()
            }

            // Widget
            ActionButton(
                icon: "rectangle.stack.badge.plus",
                label: "Widget",
                color: Color(hex: "#f472b6")  // pembe
            ) {
                WidgetService.saveFavorite(vm.activeEnvironment)
                triggerSuccessHaptic()
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheetView(text: buildMixShareMessage(
                environmentTitle:    vm.activeEnvironment.title,
                environmentCategory: vm.activeEnvironment.category.rawValue,
                masterVolume:        vm.masterVolume,
                activeSounds: Sound.all
                    .filter { vm.soundMix.state(for: $0.id).isEnabled }
                    .map { ($0.title, vm.soundMix.state(for: $0.id).volume) }
            ))
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - ActionButton

private struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(color.opacity(0.85))
                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.70))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - PressScaleButtonStyle

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.80 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - ShareSheetView (UIActivityViewController)

private struct ShareSheetView: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - AboutView

private struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColor.accentLight)
                        .symbolRenderingMode(.hierarchical)

                    Text("R: Rahatlatıcı Sesler")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)

                    Text("Doğanın huzur veren seslerini bir araya getiren bir uyku arkadaşı. Kendi karışımını oluştur, zamanlayıcı kur ve rahatça uyu.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)

                    Text("v1.0")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.40))
                        .padding(.top, 16)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppColor.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                        .foregroundStyle(AppColor.accent)
                }
            }
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColor.background)
    }
}

