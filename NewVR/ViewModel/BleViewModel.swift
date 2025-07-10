import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

/// BLE通信とUIを繋ぐViewModel（MVVMパターン）
final class BleViewModel: ObservableObject {
    
    // MARK: - Published UI Properties
    @Published var connectionStatus: String = ""
    @Published var isConnected: Bool = false
    @Published var discoveredDevicesCount: Int = 0
    @Published var errorMessage: String?
    @Published var logs: [String] = []
    
    // MARK: - Dependencies
    private let bleService: BLEServiceProtocol
    private let healthManager: HealthManagerProtocol?
    private let deviceNumberProvider: DeviceNumberProvider
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let maxLogEntries = 50
    
    // MARK: - Initialization
    init(
        bleService: BLEServiceProtocol,
        healthManager: HealthManagerProtocol? = nil,
        deviceNumberProvider: DeviceNumberProvider
    ) {
        self.bleService = bleService
        self.healthManager = healthManager
        self.deviceNumberProvider = deviceNumberProvider
        
        setupBindings()
        startConnection()
    }
    
    // MARK: - Public Methods
    func retryConnection() {
        errorMessage = nil
        startConnection()
    }
    
    func disconnect() {
        bleService.disconnect()
        addLog("🔌 手動で切断しました")
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // 接続状態の監視
        bleService.connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateConnectionStatus(state)
            }
            .store(in: &cancellables)
        
        // 発見デバイスの監視
        bleService.discoveredDevices
            .receive(on: DispatchQueue.main)
            .map { $0.count }
            .assign(to: &$discoveredDevicesCount)
        
        // ボタンイベントの監視
        bleService.buttonEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleButtonEvent(event)
            }
            .store(in: &cancellables)
        
        // エラーの監視
        bleService.errors
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
        
        // 接続デバイスの監視
        bleService.connectedDevice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                if let device = device {
                    self?.addLog("✅ \(device.name)に接続しました")
                }
            }
            .store(in: &cancellables)
    }
    
    private func startConnection() {
        guard let deviceNumber = deviceNumberProvider.deviceNumber else {
            errorMessage = "デバイス番号が設定されていません"
            return
        }
        
        addLog("🔍 デバイス\(deviceNumber)の検索を開始します")
        bleService.startScanning(for: deviceNumber)
    }
    
    private func updateConnectionStatus(_ state: BLEConnectionState) {
        connectionStatus = state.description
        isConnected = (state == .connected || state == .ready)
        
        switch state {
        case .disconnected:
            addLog("🔌 切断されました")
        case .scanning:
            addLog("🔍 スキャン中...")
        case .connecting:
            addLog("🔗 接続中...")
        case .connected:
            addLog("✅ 接続成功")
        case .ready:
            addLog("🎮 準備完了！ボタン入力を待っています")
        }
    }
    
    private func handleButtonEvent(_ event: ButtonEvent) {
        addLog("💥 ボタンが押されました！")
        
        // ヘルスマネージャーにダメージを通知
        healthManager?.takeDamage(10)
        
        // 被弾音を再生
        LaserGameAudioManager.shared.playDamageEffect()
        
        // 振動フィードバック（iOS）
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
    
    private func handleError(_ error: BLEError) {
        errorMessage = error.localizedDescription
        addLog("❌ エラー: \(error.localizedDescription)")
    }
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )
        
        let logEntry = "[\(timestamp)] \(message)"
        
        logs.append(logEntry)
        
        // ログが多すぎる場合は古いものを削除
        if logs.count > maxLogEntries {
            logs.removeFirst(logs.count - maxLogEntries)
        }
    }
}

// MARK: - Device Number Provider Implementation
extension BleViewModel: DeviceNumberProvider {
    var deviceNumber: Int? {
        let username = UserDefaults.standard.string(forKey: "username") ?? ""
        let suffix = username.suffix(1)
        
        switch suffix {
        case "1":
            return 1
        case "2":
            return 2
        default:
            return nil
        }
    }
}