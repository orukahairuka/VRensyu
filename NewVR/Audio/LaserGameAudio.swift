import AVFoundation
import UIKit
import SwiftUI
import Combine
import AudioToolbox

/// レーザーゲーム用オーディオマネージャー
class LaserGameAudioManager: ObservableObject {
    static let shared = LaserGameAudioManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var systemSoundPlayers: [String: SystemSoundPlayer] = [:]
    private var isEnabled: Bool = true
    private var hapticEnabled: Bool = true
    
    // オーディオファイル定義
    enum SoundEffect: String, CaseIterable {
        case explosion = "爆発2" // 既存のアセット
        case curse = "呪いの旋律" // 既存のアセット
        case maou = "maou" // 被弾音用のアセット
        case laserShot = "laser_shot"
        case reload = "reload"
        case radarBeep = "radar_beep"
        case buttonPress = "button_press"
        case damage = "damage"
        case powerUp = "power_up"
        case teamSelect = "team_select"
        case victory = "victory"
        case defeat = "defeat"
        case gameStart = "game_start"
        
        var fileName: String {
            switch self {
            case .explosion:
                return "爆発2.mp3"
            case .curse:
                return "呪いの旋律.mp3"
            case .maou:
                return "maou.mp3"
            default:
                return "\(rawValue).mp3"
            }
        }
    }
    
    // 触覚フィードバックタイプ
    enum HapticType {
        case light
        case medium
        case heavy
        case success
        case warning
        case error
        case selection
    }
    
    private init() {
        setupAudioSession()
        preloadSounds()
        loadSettings()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            // playbackカテゴリを使用して音声再生を有効化
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session setup successful")
        } catch {
            print("❌ Audio session setup failed: \(error)")
            
            // フォールバック：ambient カテゴリを試す
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                print("✅ Audio session setup successful (fallback to ambient)")
            } catch {
                print("❌ Audio session fallback also failed: \(error)")
            }
        }
    }
    
    private func preloadSounds() {
        for sound in SoundEffect.allCases {
            preloadSound(sound)
        }
    }
    
    private func preloadSound(_ sound: SoundEffect) {
        // データセットファイルの場合はNSDataAssetを使用
        if sound == .maou || sound == .explosion || sound == .curse {
            var datasetName = sound.rawValue
            
            // データセット名をマッピング
            switch sound {
            case .explosion:
                datasetName = "gua"
            case .maou:
                datasetName = "maou"
            case .curse:
                datasetName = "noroi"
            default:
                break
            }
            
            print("🔍 Loading dataset file: \(datasetName)")
            
            guard let dataAsset = NSDataAsset(name: datasetName) else {
                print("❌ NSDataAsset not found for: \(datasetName)")
                // フォールバック: システムサウンドを再生
                loadSystemSound(for: sound)
                return
            }
            
            print("✅ Found data asset: \(sound.rawValue) - Size: \(dataAsset.data.count) bytes")
            
            do {
                let player = try AVAudioPlayer(data: dataAsset.data)
                player.prepareToPlay()
                audioPlayers[sound.rawValue] = player
                print("✅ Audio loaded successfully from data asset: \(sound.rawValue) - Duration: \(player.duration)s")
            } catch {
                print("❌ Failed to load audio from data asset: \(sound.rawValue) - \(error)")
            }
            return
        }
        
        // 通常のファイルの場合
        print("🔍 Looking for regular file: \(sound.rawValue).mp3")
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            print("⚠️ Audio file not found: \(sound.rawValue).mp3")
            // フォールバック: システムサウンドを再生
            loadSystemSound(for: sound)
            return
        }
        
        print("✅ Found audio file at: \(url.path)")
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[sound.rawValue] = player
            print("✅ Audio loaded successfully: \(sound.rawValue) - Duration: \(player.duration)s")
        } catch {
            print("❌ Failed to load audio: \(sound.rawValue) - \(error)")
        }
    }
    
    private func loadSettings() {
        // デフォルトでは音声とバイブを有効にする
        if !UserDefaults.standard.bool(forKey: "soundEnabledSet") {
            UserDefaults.standard.set(true, forKey: "soundEnabled")
            UserDefaults.standard.set(true, forKey: "vibrationEnabled")
            UserDefaults.standard.set(true, forKey: "soundEnabledSet")
        }
        
        // デフォルトで音声を有効にする
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "soundEnabled")
        }
        if UserDefaults.standard.object(forKey: "vibrationEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "vibrationEnabled")
        }
        
        isEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        hapticEnabled = UserDefaults.standard.bool(forKey: "vibrationEnabled")
    }
    
    // システムサウンドのフォールバック
    private func loadSystemSound(for sound: SoundEffect) {
        // システムサウンドIDを使用したフォールバック
        var systemSoundID: SystemSoundID = 0
        
        switch sound {
        case .explosion, .maou:
            systemSoundID = 1051 // Received message sound
        case .curse:
            systemSoundID = 1052 // Sent message sound
        case .laserShot:
            systemSoundID = 1103 // Tweet sent
        case .reload:
            systemSoundID = 1104 // Refresh
        case .radarBeep:
            systemSoundID = 1306 // Lock sound
        case .buttonPress:
            systemSoundID = 1104 // Click
        case .gameStart:
            systemSoundID = 1025 // Anticipate
        case .defeat:
            systemSoundID = 1328 // Update
        case .victory:
            systemSoundID = 1025 // Anticipate
        case .damage:
            systemSoundID = 1051 // Received message sound
        case .powerUp:
            systemSoundID = 1057 // Tink sound
        case .teamSelect:
            systemSoundID = 1103 // Tweet sent
        }
        
        // SystemSoundPlayerを作成して保存
        let player = SystemSoundPlayer(soundID: systemSoundID)
        systemSoundPlayers[sound.rawValue] = player
        print("⚠️ Using system sound fallback for: \(sound.rawValue) - ID: \(systemSoundID)")
    }
    
    // MARK: - Sound Control
    func playSound(_ sound: SoundEffect, volume: Float = 1.0) {
        guard isEnabled else { 
            print("⚠️ Audio is disabled")
            return 
        }
        
        // まずAVAudioPlayerを試す
        if let player = audioPlayers[sound.rawValue] {
            // オーディオセッションの状態を確認
            let session = AVAudioSession.sharedInstance()
            print("🔊 Audio session category: \(session.category)")
            print("🔊 Audio session active: \(session.isOtherAudioPlaying)")
            print("🔊 System volume: \(session.outputVolume)")
            
            player.volume = volume
            player.stop() // 前の再生を停止
            player.currentTime = 0
            let success = player.play()
            print("🎵 Playing sound: \(sound.rawValue) - Success: \(success), Volume: \(volume), Duration: \(player.duration)")
            
            // 再生状態を確認
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🎵 Player state - isPlaying: \(player.isPlaying), currentTime: \(player.currentTime)")
            }
            return
        }
        
        // フォールバック: システムサウンドを試す
        if let systemPlayer = systemSoundPlayers[sound.rawValue] {
            print("⚠️ Using system sound fallback for: \(sound.rawValue)")
            systemPlayer.play()
            return
        }
        
        print("❌ No audio player available for: \(sound.rawValue)")
    }
    
    func stopSound(_ sound: SoundEffect) {
        audioPlayers[sound.rawValue]?.stop()
    }
    
    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
    }
    
    // MARK: - Haptic Feedback
    func triggerHaptic(_ type: HapticType) {
        guard hapticEnabled else { return }
        
        switch type {
        case .light:
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
            
        case .medium:
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
            
        case .heavy:
            let feedback = UIImpactFeedbackGenerator(style: .heavy)
            feedback.impactOccurred()
            
        case .success:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
            
        case .warning:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
            
        case .error:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
            
        case .selection:
            let feedback = UISelectionFeedbackGenerator()
            feedback.selectionChanged()
        }
    }
    
    // MARK: - Game-Specific Audio Events
    func playDamageEffect() {
        print("🔥 Damage effect triggered - playing explosion sound")
        playSound(.explosion, volume: 0.8)
        triggerHaptic(.heavy)
        
        // 複数回の振動でダメージ感を演出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.triggerHaptic(.medium)
        }
    }
    
    // テスト用の音声再生機能
    func testPlayExplosionSound() {
        print("🎵 Testing explosion sound playback...")
        print("🎵 Audio enabled: \(isEnabled)")
        print("🎵 Available audio players: \(audioPlayers.keys.sorted())")
        
        if let player = audioPlayers["爆発2"] {
            print("🎵 Explosion player found - Duration: \(player.duration), Volume: \(player.volume)")
        } else {
            print("❌ Explosion player not found!")
        }
        
        // システムサウンドでテスト
        print("🎵 Testing system sound...")
        AudioServicesPlaySystemSound(1000) // システムサウンド
        
        playSound(.explosion, volume: 1.0)
    }
    
    // システムサウンドテスト
    func testSystemSound() {
        print("🔊 Playing system sound...")
        AudioServicesPlaySystemSound(1000) // システムサウンド
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // バイブレーション
    }
    
    func playWeaponFire() {
        playSound(.laserShot, volume: 0.6)
        triggerHaptic(.medium)
    }
    
    func playReload() {
        playSound(.reload, volume: 0.7)
        triggerHaptic(.light)
    }
    
    func playRadarBeep() {
        playSound(.radarBeep, volume: 0.4)
        triggerHaptic(.light)
    }
    
    func playButtonPress() {
        playSound(.buttonPress, volume: 0.5)
        triggerHaptic(.selection)
    }
    
    func playTeamSelection() {
        playSound(.teamSelect, volume: 0.7)
        triggerHaptic(.success)
    }
    
    func playVictory() {
        playSound(.victory, volume: 0.9)
        triggerHaptic(.success)
        
        // 勝利の余韻
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.triggerHaptic(.success)
        }
    }
    
    func playDefeat() {
        playSound(.defeat, volume: 0.8)
        triggerHaptic(.error)
        
        // 敗北の重い感触
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                self.triggerHaptic(.heavy)
            }
        }
    }
    
    func playCriticalHealth() {
        playSound(.curse, volume: 0.6) // 呪いの旋律を使用
        triggerHaptic(.warning)
    }
    
    // MARK: - Settings
    func setSoundEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "soundEnabled")
    }
    
    func setHapticEnabled(_ enabled: Bool) {
        hapticEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "vibrationEnabled")
    }
}

// MARK: - View Extension for Audio
extension View {
    func onTapGestureWithAudio(
        audio: LaserGameAudioManager.SoundEffect = .buttonPress,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onTapGesture {
            LaserGameAudioManager.shared.playSound(audio)
            LaserGameAudioManager.shared.triggerHaptic(.selection)
            action()
        }
    }
    
    func onButtonPress(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            LaserGameAudioManager.shared.playButtonPress()
            action()
        }
    }
}

// MARK: - Audio-Enhanced Button Style
struct AudioLaserButtonStyle: ButtonStyle {
    let color: Color
    let isActive: Bool
    let soundEffect: LaserGameAudioManager.SoundEffect
    
    init(color: Color = LaserGameDesign.Colors.neonBlue, isActive: Bool = true, soundEffect: LaserGameAudioManager.SoundEffect = .buttonPress) {
        self.color = color
        self.isActive = isActive
        self.soundEffect = soundEffect
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LaserGameDesign.Typography.body)
            .foregroundColor(isActive ? color : color.opacity(0.5))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    LaserGameDesign.Colors.darkSecondary
                    
                    if configuration.isPressed {
                        color.opacity(0.2)
                    }
                }
            )
            .laserBorder(color: isActive ? color : color.opacity(0.3))
            .neonGlow(color: isActive ? color : Color.clear, radius: configuration.isPressed ? 8 : 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    LaserGameAudioManager.shared.playSound(soundEffect)
                    LaserGameAudioManager.shared.triggerHaptic(.selection)
                }
            }
    }
}

// MARK: - Health Audio Integration
class HealthAudioIntegration: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var previousHealth: Int = 300
    
    func setupHealthMonitoring(healthPublisher: Published<Int>.Publisher) {
        healthPublisher
            .dropFirst()
            .sink { [weak self] newHealth in
                guard let self = self else { return }
                
                if newHealth < self.previousHealth {
                    LaserGameAudioManager.shared.playDamageEffect()
                    
                    // クリティカル状態の警告音
                    if newHealth <= 50 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            LaserGameAudioManager.shared.playCriticalHealth()
                        }
                    }
                }
                
                self.previousHealth = newHealth
            }
            .store(in: &cancellables)
    }
    
    func setupConnectionMonitoring(connectionPublisher: Published<Bool>.Publisher) {
        connectionPublisher
            .dropFirst()
            .sink { connected in
                if connected {
                    LaserGameAudioManager.shared.playSound(.powerUp)
                    LaserGameAudioManager.shared.triggerHaptic(.success)
                } else {
                    LaserGameAudioManager.shared.triggerHaptic(.error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Notification Center Integration
extension LaserGameAudioManager {
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .damageReceived,
            object: nil,
            queue: .main
        ) { _ in
            self.playDamageEffect()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.setupAudioSession()
        }
    }
}
