import UIKit

// MARK: - Haptic Helpers

func triggerSelectionHaptic() {
    let generator = UISelectionFeedbackGenerator()
    generator.prepare()
    generator.selectionChanged()
}

func triggerSoftImpactHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .soft)
    generator.prepare()
    generator.impactOccurred()
}

func triggerMediumImpactHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare()
    generator.impactOccurred()
}

func triggerSuccessHaptic() {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(.success)
}
