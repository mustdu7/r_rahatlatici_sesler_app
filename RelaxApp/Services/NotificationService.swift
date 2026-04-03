import UserNotifications

// MARK: - NotificationService

actor NotificationService {

    static let shared = NotificationService()
    private init() {}

    private let notificationId = "relax.sleep.timer.end"

    // MARK: - İzin İste

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                print("[NotificationService] Bildirim izni reddedildi.")
            }
        } catch {
            print("[NotificationService] İzin hatası: \(error.localizedDescription)")
        }
    }

    // MARK: - Timer Bildirimi Planla

    func scheduleTimerEndNotification(in seconds: Double) async {
        // Önce varsa önceki bildirimi iptal et
        await cancelTimerNotification()

        let content = UNMutableNotificationContent()
        content.title  = "R: Rahatlatıcı Sesler"
        content.body   = randomSleepMessage()
        content.sound  = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("[NotificationService] Bildirim eklenemedi: \(error.localizedDescription)")
        }
    }

    // MARK: - Timer Bildirimini İptal Et

    func cancelTimerNotification() async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationId])
    }

    // MARK: - Rastgele Mesaj

    private func randomSleepMessage() -> String {
        let messages = [
            "İyi geceler! 🌙 Umarım güzel rüyalar görürsün.",
            "Hoş bir uyku! Sesler kapandı, şimdi dinlen.",
            "Zamanlayıcın tamamlandı. Tatlı rüyalar! ✨"
        ]
        return messages.randomElement() ?? messages[0]
    }
}
