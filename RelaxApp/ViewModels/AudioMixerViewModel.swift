import AVFoundation
import Combine
import MediaPlayer
import SwiftUI
import UIKit

// MARK: - AudioMixerViewModel

@MainActor
class AudioMixerViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedEnvironmentId: String = "rainy-window"
    @Published var soundMix: MixMap = [:]
    @Published var masterVolume: Double = 80
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var isAudioReady: Bool = false
    @Published var sleepTimerMinutes: Int? = nil
    @Published var remainingTimerLabel: String = ""

    // MARK: - Ses Motoru (AVAudioEngine — kesintisiz loop)

    private let audioEngine = AVAudioEngine()
    private var playerNodes:  [SoundId: AVAudioPlayerNode]  = [:]
    private var mixerNodes:   [SoundId: AVAudioMixerNode]   = [:]
    private var audioBuffers: [SoundId: AVAudioPCMBuffer]   = [:]

    private var crossfadeTimer: Timer?
    private var fadeInTimer: Timer?
    private var sleepTimer: Timer?
    private var countdownTimer: Timer?
    private var timerEndDate: Date?

    // Stale Task'ları önlemek için nesil sayaçları
    private var crossfadeGeneration = 0
    private var fadeInGeneration    = 0

    // MARK: - Sabitler

    let crossfadeDuration: Double = 1.2
    let sleepFadeDuration: Double = 14.0
    let animationStep: Double     = 0.05

    // MARK: - Başlatma

    init() {
        setupAudioSession()
        preloadPlayers()
        let firstEnv = AppEnvironment.all.first ?? AppEnvironment.all[0] // static data, never empty
        selectedEnvironmentId = firstEnv.id
        soundMix = defaultMix(for: firstEnv)
        applyVolumes(animated: false)
        isAudioReady = true
        setupRemoteCommands()
        updateNowPlayingInfo()
    }

    deinit {
        crossfadeTimer?.invalidate()
        fadeInTimer?.invalidate()
        sleepTimer?.invalidate()
        countdownTimer?.invalidate()
        audioEngine.stop()
    }

    // MARK: - AVAudioSession

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[session] Hata: \(error)")
        }

        Task { [weak self] in
            await self?.observeAudioInterruptions()
        }
    }

    private func observeAudioInterruptions() async {
        let notifications = NotificationCenter.default.notifications(
            named: AVAudioSession.interruptionNotification
        )
        for await notification in notifications {
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { continue }

            switch type {
            case .began:
                if isPlaying {
                    isPlaying = false
                    updateNowPlayingInfo()
                }
            case .ended:
                let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let shouldResume = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    .contains(.shouldResume)
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    if !audioEngine.isRunning { try audioEngine.start() }
                } catch {
                    print("[session] Yeniden aktive hatası: \(error)")
                }
                if shouldResume { play() }
            @unknown default: break
            }
        }
    }

    // MARK: - Player Ön Yükleme

    private func preloadPlayers() {
        let bundlePath = Bundle.main.bundlePath
        let fm = FileManager.default

        for sound in Sound.all {
            let candidates = [
                bundlePath + "/" + sound.audioFileName,
                bundlePath + "/Audio/" + sound.audioFileName
            ]
            guard let filePath = candidates.first(where: { fm.fileExists(atPath: $0) }) else {
                print("[preload] BULUNAMADI: \(sound.audioFileName)")
                continue
            }

            let fileURL = URL(fileURLWithPath: filePath)
            do {
                let audioFile = try AVAudioFile(forReading: fileURL)
                guard let buffer = AVAudioPCMBuffer(
                    pcmFormat: audioFile.processingFormat,
                    frameCapacity: AVAudioFrameCount(audioFile.length)
                ) else { continue }
                try audioFile.read(into: buffer)

                let playerNode = AVAudioPlayerNode()
                let mixerNode  = AVAudioMixerNode()

                audioEngine.attach(playerNode)
                audioEngine.attach(mixerNode)
                audioEngine.connect(playerNode, to: mixerNode, format: buffer.format)
                audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: buffer.format)

                mixerNode.outputVolume = 0

                playerNodes[sound.id]  = playerNode
                mixerNodes[sound.id]   = mixerNode
                audioBuffers[sound.id] = buffer

                print("[preload] OK: \(sound.audioFileName)")
            } catch {
                print("[preload] Hata (\(sound.audioFileName)): \(error)")
            }
        }

        print("[preload] Toplam player: \(playerNodes.count)/\(Sound.all.count)")

        do {
            try audioEngine.start()
            print("[engine] Başlatıldı")
        } catch {
            print("[engine] Başlatma hatası: \(error)")
        }
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlay() }
            return .success
        }
    }

    // MARK: - Hesaplanmış Özellikler

    var activeEnvironment: AppEnvironment {
        AppEnvironment.environment(for: selectedEnvironmentId)
            ?? AppEnvironment.all[0]
    }

    var activeSoundsCount: Int {
        soundMix.values.filter { $0.isEnabled }.count
    }

    var sortedSounds: [Sound] {
        Sound.all.sorted { a, b in
            let aEnabled = soundMix[a.id]?.isEnabled ?? false
            let bEnabled = soundMix[b.id]?.isEnabled ?? false
            if aEnabled != bEnabled { return aEnabled }
            return a.title < b.title
        }
    }

    // MARK: - Ses Kontrolü

    func play() {
        guard isAudioReady else { return }
        isPlaying = true

        if !audioEngine.isRunning {
            try? audioEngine.start()
        }

        // Tüm sesleri sıfırdan başlat, fade-in ile yükselt
        for sound in Sound.all {
            let state = soundMix.state(for: sound.id)
            guard state.isEnabled,
                  let playerNode = playerNodes[sound.id],
                  let buffer = audioBuffers[sound.id],
                  let mixerNode = mixerNodes[sound.id] else { continue }

            if !playerNode.isPlaying {
                mixerNode.outputVolume = 0
                playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
                playerNode.play()
            }
        }

        startFadeIn()
        updateNowPlayingInfo()
        triggerMediumImpactHaptic()
    }

    private func startFadeIn() {
        fadeInTimer?.invalidate()
        fadeInGeneration += 1
        let generation   = fadeInGeneration
        let fadeInDuration = 2.0
        let steps = Int(fadeInDuration / animationStep)
        var step = 0

        fadeInTimer = Timer.scheduledTimer(withTimeInterval: animationStep, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            let t = min(Double(step) / Double(steps), 1.0)

            Task { @MainActor [weak self] in
                guard let self, self.fadeInGeneration == generation else { return }
                for sound in Sound.all {
                    guard let mixerNode = self.mixerNodes[sound.id] else { continue }
                    let state = self.soundMix.state(for: sound.id)
                    guard state.isEnabled else { continue }
                    mixerNode.outputVolume = Float(self.finalVolume(soundVolume: state.volume) * easeIn(t))
                }
                if t >= 1 { timer.invalidate() }
            }
        }
    }

    func pause() {
        isPlaying = false
        fadeInTimer?.invalidate()
        fadeInTimer = nil
        for playerNode in playerNodes.values { playerNode.pause() }
        updateNowPlayingInfo()
        triggerMediumImpactHaptic()
    }

    func togglePlay() {
        isPlaying ? pause() : play()
    }

    func setMute(_ muted: Bool) {
        isMuted = muted
        applyVolumes(animated: false)
    }

    func setMasterVolume(_ v: Double) {
        masterVolume = v.clamped(to: 0...100)
        applyVolumes(animated: false)
    }

    func setSoundVolume(id: SoundId, volume: Double) {
        soundMix[id]?.volume = volume.clamped(to: 0...100)
        let state = soundMix.state(for: id)
        if state.isEnabled {
            mixerNodes[id]?.outputVolume = Float(finalVolume(soundVolume: state.volume))
        }
    }

    func toggleSound(id: SoundId) {
        soundMix[id]?.isEnabled.toggle()
        let state = soundMix.state(for: id)
        guard let playerNode = playerNodes[id],
              let buffer = audioBuffers[id],
              let mixerNode = mixerNodes[id] else { return }

        if state.isEnabled {
            mixerNode.outputVolume = Float(finalVolume(soundVolume: state.volume))
            if isPlaying && !playerNode.isPlaying {
                playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
                playerNode.play()
            }
        } else {
            mixerNode.outputVolume = 0
            playerNode.stop()
        }

        triggerSelectionHaptic()
        updateNowPlayingInfo()
    }

    func resetMix() {
        soundMix = defaultMix(for: activeEnvironment)
        applyVolumes(animated: true)
        updateNowPlayingInfo()
        triggerSoftImpactHaptic()
    }

    // MARK: - Ortam Değiştirme

    func selectEnvironment(_ id: String) {
        guard id != selectedEnvironmentId,
              let targetEnv = AppEnvironment.environment(for: id) else { return }

        // Tüm aktif timer'ları ve stale Task'ları iptal et
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        fadeInTimer?.invalidate()
        fadeInTimer = nil
        crossfadeGeneration += 1
        fadeInGeneration    += 1

        let oldMix = soundMix
        let newMix = defaultMix(for: targetEnv)

        selectedEnvironmentId = id
        soundMix = newMix

        // Yeni mixes'te olmayan sesleri hemen durdur
        for sound in Sound.all {
            let wasEnabled  = oldMix[sound.id]?.isEnabled ?? false
            let willEnabled = newMix[sound.id]?.isEnabled ?? false
            if wasEnabled && !willEnabled {
                mixerNodes[sound.id]?.outputVolume = 0
                playerNodes[sound.id]?.stop()
            }
        }

        if isPlaying { crossfade(from: oldMix, to: newMix) }

        updateNowPlayingInfo()
        WidgetService.saveFavorite(activeEnvironment)
        triggerSoftImpactHaptic()
    }

    // MARK: - Crossfade

    private func crossfade(from oldMix: MixMap, to newMix: MixMap) {
        crossfadeGeneration += 1
        let generation = crossfadeGeneration
        let steps = Int(crossfadeDuration / animationStep)
        var step  = 0

        crossfadeTimer = Timer.scheduledTimer(withTimeInterval: animationStep, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }

            step += 1
            let clampedT = min(Double(step) / Double(steps), 1.0)

            Task { @MainActor [weak self] in
                // Nesil uyuşmuyorsa bu timer artık geçersiz — sessizce çık
                guard let self, self.crossfadeGeneration == generation else { return }

                for sound in Sound.all {
                    guard let mixerNode = self.mixerNodes[sound.id] else { continue }
                    let wasEnabled = oldMix[sound.id]?.isEnabled ?? false
                    let isEnabled  = newMix[sound.id]?.isEnabled ?? false

                    if wasEnabled && !isEnabled {
                        // Eski ses zaten stop() edildi; volume'u 0'da tut
                        mixerNode.outputVolume = 0
                    } else if !wasEnabled && isEnabled {
                        let fade = easeIn(clampedT)
                        let vol  = newMix[sound.id]?.volume ?? 0
                        if let playerNode = self.playerNodes[sound.id],
                           let buffer = self.audioBuffers[sound.id],
                           self.isPlaying && !playerNode.isPlaying {
                            await playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
                            playerNode.play()
                        }
                        mixerNode.outputVolume = Float(self.finalVolume(soundVolume: vol) * fade)
                    } else if wasEnabled && isEnabled {
                        let oldVol = oldMix[sound.id]?.volume ?? 0
                        let newVol = newMix[sound.id]?.volume ?? 0
                        let vol    = oldVol + (newVol - oldVol) * clampedT
                        mixerNode.outputVolume = Float(self.finalVolume(soundVolume: vol))
                    }
                }

                if clampedT >= 1 {
                    timer.invalidate()
                    self.applyVolumes(animated: false)
                }
            }
        }
    }

    // MARK: - Uyku Zamanlayıcısı

    func setSleepTimer(minutes: Int) {
        clearSleepTimer()
        sleepTimerMinutes = minutes
        timerEndDate = Date().addingTimeInterval(Double(minutes) * 60)
        WidgetService.saveTimerEndDate(timerEndDate)

        Task {
            await NotificationService.shared.scheduleTimerEndNotification(
                in: Double(minutes) * 60
            )
        }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let end = self.timerEndDate else { return }
                let remaining = Int(end.timeIntervalSinceNow)
                if remaining <= 0 {
                    self.countdownTimer?.invalidate()
                    self.remainingTimerLabel = ""
                    self.beginSleepFade()
                } else {
                    self.remainingTimerLabel = formatRemainingDuration(remaining)
                }
            }
        }
    }

    func clearSleepTimer(withHaptic: Bool = false) {
        sleepTimerMinutes = nil
        remainingTimerLabel = ""
        timerEndDate = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        sleepTimer?.invalidate()
        sleepTimer = nil
        WidgetService.saveTimerEndDate(nil)
        Task { await NotificationService.shared.cancelTimerNotification() }
        if withHaptic { triggerSelectionHaptic() }
    }

    private func beginSleepFade() {
        sleepTimerMinutes = nil
        let steps = Int(sleepFadeDuration / animationStep)
        var step  = 0

        sleepTimer = Timer.scheduledTimer(withTimeInterval: animationStep, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            let t = min(Double(step) / Double(steps), 1.0)

            Task { @MainActor [weak self] in
                guard let self else { return }
                for sound in Sound.all {
                    guard let mixerNode = self.mixerNodes[sound.id] else { continue }
                    let state = self.soundMix.state(for: sound.id)
                    guard state.isEnabled else { continue }
                    mixerNode.outputVolume = Float(self.finalVolume(soundVolume: state.volume) * (1.0 - t))
                }
                if t >= 1 {
                    timer.invalidate()
                    self.pause()
                    self.applyVolumes(animated: false)
                }
            }
        }
    }

    // MARK: - Hacim Uygula

    private func applyVolumes(animated: Bool) {
        for sound in Sound.all {
            guard let mixerNode = mixerNodes[sound.id] else { continue }
            let state = soundMix.state(for: sound.id)
            let vol   = finalVolume(soundVolume: state.volume)

            if state.isEnabled {
                mixerNode.outputVolume = Float(vol)
                if isPlaying,
                   let playerNode = playerNodes[sound.id],
                   let buffer = audioBuffers[sound.id],
                   !playerNode.isPlaying {
                    playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
                    playerNode.play()
                }
            } else {
                mixerNode.outputVolume = 0
                playerNodes[sound.id]?.stop()
            }
        }
    }

    // MARK: - Hacim Formülü

    func finalVolume(soundVolume: Double) -> Double {
        guard !isMuted else { return 0 }
        return (soundVolume / 100.0) * (masterVolume / 100.0)
    }

    // MARK: - Lock Screen / NowPlaying

    func updateNowPlayingInfo() {
        let env = activeEnvironment
        let activeNames = Sound.all
            .filter { soundMix.state(for: $0.id).isEnabled }
            .map { $0.title }
            .joined(separator: ", ")

        let timerLabel = sleepTimerMinutes.map { formatMinutesLabel($0) } ?? "Sonsuz"

        var info: [String: Any] = [
            MPMediaItemPropertyTitle:             env.title,
            MPMediaItemPropertyArtist:            "R: Rahatlatıcı Sesler",
            MPMediaItemPropertyAlbumTitle:        activeNames.isEmpty ? "Sessizlik" : activeNames,
            MPMediaItemPropertyAlbumArtist:       timerLabel,
            MPNowPlayingInfoPropertyIsLiveStream: true as NSNumber,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 as NSNumber : 0.0 as NSNumber
        ]

        if let uiImage = UIImage(named: "AppIcon") {
            let artwork = MPMediaItemArtwork(boundsSize: uiImage.size) { _ in uiImage }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

// MARK: - Easing Functions

private func easeIn(_ t: Double) -> Double  { t * t }
private func easeOut(_ t: Double) -> Double { 1 - (1 - t) * (1 - t) }

// MARK: - Comparable Clamp

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
