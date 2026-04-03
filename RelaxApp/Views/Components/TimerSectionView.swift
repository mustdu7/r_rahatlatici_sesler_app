import SwiftUI

// MARK: - TimerSectionView

struct TimerSectionView: View {
    @EnvironmentObject var vm: AudioMixerViewModel
    @State private var showCustomSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zamanlayıcı")
                .sectionTitle()

            // Preset butonlar — yatay scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(timerOptions) { option in
                        TimerChip(
                            option: option,
                            isSelected: vm.sleepTimerMinutes == option.minutes && option.minutes > 0,
                            onTap: {
                                if option.minutes == 0 {
                                    showCustomSheet = true
                                } else if vm.sleepTimerMinutes == option.minutes {
                                    vm.clearSleepTimer(withHaptic: true)
                                } else {
                                    vm.setSleepTimer(minutes: option.minutes)
                                    triggerSoftImpactHaptic()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -AppSpacing.md)

            // Aktif timer göstergesi
            if let _ = vm.sleepTimerMinutes, !vm.remainingTimerLabel.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundStyle(AppColor.accentLight)
                    Text("\(vm.remainingTimerLabel) sonra kapanacak")
                        .timerDescription()
                    Spacer()
                    Button {
                        vm.clearSleepTimer(withHaptic: true)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColor.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(AppColor.accent.opacity(0.20), lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showCustomSheet) {
            CustomTimerSheet(isPresented: $showCustomSheet)
                .environmentObject(vm)
        }
        .animation(.spring(duration: 0.3), value: vm.sleepTimerMinutes)
    }
}

// MARK: - TimerChip

private struct TimerChip: View {
    let option: TimerOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(option.label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : AppColor.textSecondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient.accentButtonGradient)
                        : AnyShapeStyle(AppColor.surface2)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(
                            isSelected ? AppColor.accent.opacity(0.5) : Color.white.opacity(0.07),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - CustomTimerSheet

private struct CustomTimerSheet: View {
    @EnvironmentObject var vm: AudioMixerViewModel
    @Binding var isPresented: Bool
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.sm) {
                    Text("Özel Süre")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Kaç dakika sonra kapansın?")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.top, AppSpacing.xl)

                // Dakika girişi
                HStack {
                    TextField("dakika", text: $inputText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .focused($isFocused)
                        .frame(width: 140)

                    Text("dk")
                        .font(.title2)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(AppSpacing.lg)
                .background(AppColor.surface2)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

                // Uygula
                Button {
                    if let minutes = Int(inputText), minutes > 0 {
                        vm.setSleepTimer(minutes: minutes)
                        triggerSuccessHaptic()
                    }
                    isPresented = false
                } label: {
                    Text("Uygula")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.accentButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
                .disabled((Int(inputText) ?? 0) <= 0)
                .opacity((Int(inputText) ?? 0) > 0 ? 1 : 0.5)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .background(AppColor.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { isPresented = false }
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .onAppear { isFocused = true }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
