import Foundation
import Combine

/// BLEサービスのプロトコル
protocol BLEServiceProtocol: AnyObject {
    /// 接続状態
    var connectionState: CurrentValueSubject<BLEConnectionState, Never> { get }
    
    /// 発見されたデバイス
    var discoveredDevices: CurrentValueSubject<[BLEDevice], Never> { get }
    
    /// 接続中のデバイス
    var connectedDevice: CurrentValueSubject<BLEDevice?, Never> { get }
    
    /// ボタンイベント
    var buttonEvents: PassthroughSubject<ButtonEvent, Never> { get }
    
    /// エラー
    var errors: PassthroughSubject<BLEError, Never> { get }
    
    /// スキャン開始
    func startScanning(for deviceNumber: Int)
    
    /// スキャン停止
    func stopScanning()
    
    /// デバイスに接続
    func connect(to device: BLEDevice)
    
    /// 切断
    func disconnect()
    
    /// 最後に接続したデバイスに再接続
    func reconnectToLastDevice()
}

/// デバイス番号プロバイダー
protocol DeviceNumberProvider {
    var deviceNumber: Int? { get }
}

/// ヘルスマネージャープロトコル
protocol HealthManagerProtocol: AnyObject {
    var currentHealth: Int { get }
    func takeDamage(_ amount: Int)
    func resetHealth()
}