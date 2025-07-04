import Foundation
import CoreBluetooth

/// ESP32デバイスを表すモデル
struct BLEDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
    let rssi: Int
    let lastSeen: Date
    
    var isTargetDevice: Bool {
        name.contains("ESP32 IR Button")
    }
    
    var deviceNumber: Int? {
        if name.contains("ESP32 IR Button 1") {
            return 1
        } else if name.contains("ESP32 IR Button 2") {
            return 2
        }
        return nil
    }
    
    static func == (lhs: BLEDevice, rhs: BLEDevice) -> Bool {
        lhs.id == rhs.id
    }
}

/// BLE接続の状態
enum BLEConnectionState {
    case disconnected
    case scanning
    case connecting
    case connected
    case ready  // サービスとキャラクタリスティック発見済み
    
    var description: String {
        switch self {
        case .disconnected:
            return "🔌 未接続"
        case .scanning:
            return "🔍 スキャン中"
        case .connecting:
            return "🔗 接続中"
        case .connected:
            return "✅ 接続済み"
        case .ready:
            return "🎮 準備完了"
        }
    }
}

/// BLE関連のエラー
enum BLEError: LocalizedError {
    case bluetoothNotAvailable
    case deviceNotFound
    case connectionFailed(String)
    case serviceNotFound
    case characteristicNotFound
    case invalidDeviceNumber
    
    var errorDescription: String? {
        switch self {
        case .bluetoothNotAvailable:
            return "Bluetoothが利用できません"
        case .deviceNotFound:
            return "デバイスが見つかりません"
        case .connectionFailed(let reason):
            return "接続に失敗しました: \(reason)"
        case .serviceNotFound:
            return "必要なサービスが見つかりません"
        case .characteristicNotFound:
            return "必要なキャラクタリスティックが見つかりません"
        case .invalidDeviceNumber:
            return "無効なデバイス番号です"
        }
    }
}

/// BLE設定
struct BLEConfiguration {
    let scanTimeout: TimeInterval
    let rssiThreshold: Int
    let allowDuplicates: Bool
    let autoReconnect: Bool
    
    static let `default` = BLEConfiguration(
        scanTimeout: 3.0,
        rssiThreshold: -80,
        allowDuplicates: true,
        autoReconnect: true
    )
    
    func serviceUUID(for deviceNumber: Int) -> CBUUID? {
        switch deviceNumber {
        case 1:
            return CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
        case 2:
            return CBUUID(string: "12345678-0002-0002-0002-123456789ABC")
        default:
            return nil
        }
    }
    
    func characteristicUUID(for deviceNumber: Int) -> CBUUID? {
        switch deviceNumber {
        case 1:
            return CBUUID(string: "87654321-4321-4321-4321-CBA987654321")
        case 2:
            return CBUUID(string: "87654321-0002-0002-0002-CBA987654321")
        default:
            return nil
        }
    }
}

/// ボタンイベント
struct ButtonEvent {
    let timestamp: Date
    let deviceId: UUID
    let rawData: Data
    let message: String?
    
    var isValidButtonPress: Bool {
        guard let msg = message else { return false }
        return msg.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .contains("button")
    }
}