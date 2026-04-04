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
    @Published var masterVolume: Double = 55
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
    private var nowPlayingTimer: Timer?       // elapsed time günceller
    private var timerEndDate: Date?
    private var playbackStartDate: Date?      // elapsed hesabı için
    private var remoteCommandTokens: [Any] = []
    private var artworkCache: [String: UIImage] = [:]   // envId → indirilen thumbnail

    // Stale Task'ları önlemek için nesil sayaçları
    private var crossfadeGeneration = 0
    private var fadeInGeneration    = 0

    // MARK: - Sabitler

    let crossfadeDuration: Double = 1.2
    let sleepFadeDuration: Double = 14.0
    let animationStep: Double     = 0.05

    // MARK: - Başlatma

    init() {
        let firstEnv = AppEnvironment.all[0]
        selectedEnvironmentId = firstEnv.id
        soundMix = defaultMix(for: firstEnv)
        setupAudioSession()
        setupRemoteCommands()
        updateNowPlayingInfo()
        // Dosya okuma background'da; UI hemen render edilir
        Task { await preloadPlayers() }
    }

    deinit {
        crossfadeTimer?.invalidate()
        fadeInTimer?.invalidate()
        sleepTimer?.invalidate()
        countdownTimer?.invalidate()
        nowPlayingTimer?.invalidate()
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

    private func preloadPlayers() async {
        struct LoadedItem {
            let id: SoundId
            let buffer: AVAudioPCMBuffer
        }

        let bundlePath = Bundle.main.bundlePath
        let fm = FileManager.default
        let sounds = Sound.all

        // Dosya okuma — background thread (main'i bloke etmez)
        let items: [LoadedItem] = await Task.detached(priority: .userInitiated) {
            var results: [LoadedItem] = []
            for sound in sounds {
                let candidates = [
                    bundlePath + "/" + sound.audioFileName,
                    bundlePath + "/Audio/" + sound.audioFileName
                ]
                guard let filePath = candidates.first(where: { fm.fileExists(atPath: $0) }) else {
                    print("[preload] BULUNAMADI: \(sound.audioFileName)")
                    continue
                }
                do {
                    let audioFile = try AVAudioFile(forReading: URL(fileURLWithPath: filePath))
                    guard let buffer = AVAudioPCMBuffer(
                        pcmFormat: audioFile.processingFormat,
                        frameCapacity: AVAudioFrameCount(audioFile.length)
                    ) else { continue }
                    try audioFile.read(into: buffer)
                    results.append(LoadedItem(id: sound.id, buffer: buffer))
                    print("[preload] OK: \(sound.audioFileName)")
                } catch {
                    print("[preload] Hata (\(sound.audioFileName)): \(error)")
                }
            }
            return results
        }.value

        // Engine bağlantıları — main thread (AVAudioEngine gereksinimi)
        for item in items {
            let playerNode = AVAudioPlayerNode()
            let mixerNode  = AVAudioMixerNode()
            audioEngine.attach(playerNode)
            audioEngine.attach(mixerNode)
            audioEngine.connect(playerNode, to: mixerNode, format: item.buffer.format)
            audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: item.buffer.format)
            mixerNode.outputVolume = 0
            playerNodes[item.id]  = playerNode
            mixerNodes[item.id]   = mixerNode
            audioBuffers[item.id] = item.buffer
        }

        print("[preload] Toplam player: \(playerNodes.count)/\(Sound.all.count)")

        do {
            try audioEngine.start()
            print("[engine] Başlatıldı")
        } catch {
            print("[engine] Başlatma hatası: \(error)")
        }

        isAudioReady = true
        applyVolumes(animated: false)
        updateNowPlayingInfo()
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // addTarget { } token'ları saklanmazsa handler anında deregister olur → widget görünmez
        commandCenter.playCommand.isEnabled = true
        let playToken = commandCenter.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.play() }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        let pauseToken = commandCenter.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.pause() }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        let toggleToken = commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.togglePlay() }
            return .success
        }

        // Kilit ekranı "İleri / Geri" → ortam değiştirme
        commandCenter.nextTrackCommand.isEnabled = true
        let nextToken = commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let envs = AppEnvironment.all
                if let idx = envs.firstIndex(where: { $0.id == self.selectedEnvironmentId }),
                   idx + 1 < envs.count {
                    self.selectEnvironment(envs[idx + 1].id)
                }
            }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        let prevToken = commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let envs = AppEnvironment.all
                if let idx = envs.firstIndex(where: { $0.id == self.selectedEnvironmentId }),
                   idx - 1 >= 0 {
                    self.selectEnvironment(envs[idx - 1].id)
                }
            }
            return .success
        }

        remoteCommandTokens = [playToken, pauseToken, toggleToken, nextToken, prevToken]
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
        playbackStartDate = Date()

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
        startNowPlayingTimer()
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
            MainActor.assumeIsolated {
                guard let self, self.fadeInGeneration == generation else { timer.invalidate(); return }
                step += 1
                let t = min(Double(step) / Double(steps), 1.0)

                for sound in Sound.all {
                    guard let mixerNode = self.mixerNodes[sound.id] else { continue }
                    let state = self.soundMix.state(for: sound.id)
                    guard state.isEnabled else { continue }
                    // Yalnızca yükselt — toggleSound ile zaten açılmış sesleri düşürme
                    let target = Float(self.finalVolume(soundVolume: state.volume) * easeIn(t))
                    if target > mixerNode.outputVolume {
                        mixerNode.outputVolume = target
                    }
                }
                if t >= 1 { timer.invalidate() }
            }
        }
    }

    func pause() {
        isPlaying = false
        fadeInTimer?.invalidate()
        fadeInTimer = nil
        nowPlayingTimer?.invalidate()
        nowPlayingTimer = nil
        // stop() kullan: pause() buffer'ı kuyrukta bırakır, play() sonrası çift buffer → faz iptali
        for playerNode in playerNodes.values { playerNode.stop() }
        // Tüm mixer volume'ları sıfırla; play() fade-in ile temiz başlar
        for mixerNode in mixerNodes.values { mixerNode.outputVolume = 0 }
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
            if isPlaying {
                // Engine çalışıyor: temiz başlat
                if playerNode.isPlaying { playerNode.stop() }
                playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
                playerNode.play()
                mixerNode.outputVolume = Float(finalVolume(soundVolume: state.volume))
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

        // Tüm çalan sesleri durdur ve mixer'ları temizle
        for sound in Sound.all {
            mixerNodes[sound.id]?.outputVolume = 0
            playerNodes[sound.id]?.stop()
        }

        if isPlaying {
            playbackStartDate = Date()   // yeni ortam → elapsed sıfırla
            crossfade(from: oldMix, to: newMix)
        }

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
            MainActor.assumeIsolated {
                guard let self, self.crossfadeGeneration == generation else { timer.invalidate(); return }

                step += 1
                let clampedT = min(Double(step) / Double(steps), 1.0)

                for sound in Sound.all {
                    guard let mixerNode = self.mixerNodes[sound.id] else { continue }
                    let wasEnabled = oldMix[sound.id]?.isEnabled ?? false
                    let isEnabled  = newMix[sound.id]?.isEnabled ?? false

                    if wasEnabled && !isEnabled {
                        mixerNode.outputVolume = 0
                    } else if !wasEnabled && isEnabled {
                        // Senkron scheduleBuffer — .loops ile await asla dönmez
                        if let playerNode = self.playerNodes[sound.id],
                           let buffer = self.audioBuffers[sound.id],
                           self.isPlaying && !playerNode.isPlaying {
                            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
                            playerNode.play()
                        }
                        let fade = easeIn(clampedT)
                        let vol  = newMix[sound.id]?.volume ?? 0
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
            MainActor.assumeIsolated {
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
            MainActor.assumeIsolated {
                guard let self else { timer.invalidate(); return }
                step += 1
                let t = min(Double(step) / Double(steps), 1.0)

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

    // MARK: - Lock Screen / Now Playing

    private func startNowPlayingTimer() {
        nowPlayingTimer?.invalidate()
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isPlaying else { return }
                // Sadece elapsed time güncelle; artwork/title'ı yeniden oluşturma
                guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
                let elapsed = self.playbackStartDate.map { Date().timeIntervalSince($0) } ?? 0
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed as NSNumber
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }
    }

    func updateNowPlayingInfo() {
        let env = activeEnvironment
        let artworkSize = CGSize(width: 600, height: 600)
        let elapsed = playbackStartDate.map { Date().timeIntervalSince($0) } ?? 0

        // Artwork: cache'li thumbnail → yoksa app icon fallback
        let artworkImage: UIImage
        if let cached = artworkCache[env.id] {
            artworkImage = cached
        } else {
            artworkImage = UIImage(named: "NowPlayingArtwork") ?? UIImage()
            Task { await fetchAndCacheArtwork(for: env) }
        }
        let artwork = MPMediaItemArtwork(boundsSize: artworkSize) { _ in artworkImage }

        // duration: 3600 saniye sembolik → progress bar görünür; isLiveStream: false → "CANLI" yok
        let info: [String: Any] = [
            MPMediaItemPropertyTitle:                    env.title,
            MPMediaItemPropertyArtist:                   "R: Rahatlatıcı Sesler",
            MPMediaItemPropertyArtwork:                  artwork,
            MPMediaItemPropertyPlaybackDuration:         3600.0 as NSNumber,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed as NSNumber,
            MPNowPlayingInfoPropertyPlaybackRate:        isPlaying ? 1.0 as NSNumber : 0.0 as NSNumber,
            MPNowPlayingInfoPropertyIsLiveStream:        false as NSNumber
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    private func fetchAndCacheArtwork(for env: AppEnvironment) async {
        guard artworkCache[env.id] == nil,
              let url = URL(string: env.thumbnailUrl) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return }
        artworkCache[env.id] = image
        if selectedEnvironmentId == env.id { updateNowPlayingInfo() }
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
