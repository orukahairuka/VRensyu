import AVFoundation
import UIKit
import SwiftUI
import Combine

/// レーザーゲーム用オーディオマネージャー
class LaserGameAudioManager: ObservableObject {
    static let shared = LaserGameAudioManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isEnabled: Bool = true
    private var hapticEnabled: Bool = true
    
    // オーディオファイル定義
    enum SoundEffect: String, CaseIterable {
        case explosion = "爆発2" // 既存のアセット
        case curse = "呪いの旋律" // 既存のアセット
        case laserShot = "laser_shot"
        case reload = "reload"
        case radarBeep = "radar_beep"
        case buttonPress = "button_press"
        case damage = "damage"
        case powerUp = "power_up"
        case teamSelect = "team_select"
        case victory = "victory"
        case defeat = "defeat"
        
        var fileName: String {
            switch self {
            case .explosion:
                return "爆発2.mp3"
            case .curse:
                return "呪いの旋律.mp3"
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
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }
    
    private func preloadSounds() {
        for sound in SoundEffect.allCases {
            preloadSound(sound)
        }
    }
    
    private func preloadSound(_ sound: SoundEffect) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                        Bundle.main.url(forResource: sound.fileName, withExtension: nil) else {
            print("⚠️ Audio file not found: \(sound.fileName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[sound.rawValue] = player
        } catch {
            print("❌ Failed to load audio: \(sound.fileName) - \(error)")
        }
    }
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        hapticEnabled = UserDefaults.standard.bool(forKey: "vibrationEnabled")
    }
    
    // MARK: - Sound Control
    func playSound(_ sound: SoundEffect, volume: Float = 1.0) {
        guard isEnabled else { return }
        
        guard let player = audioPlayers[sound.rawValue] else {
            print("⚠️ Audio player not found for: \(sound.rawValue)")
            return
        }
        
        player.volume = volume
        player.stop() // 前の再生を停止
        player.currentTime = 0
        player.play()
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
        playSound(.explosion, volume: 0.8)
        triggerHaptic(.heavy)
        
        // 複数回の振動でダメージ感を演出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.triggerHaptic(.medium)
        }
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