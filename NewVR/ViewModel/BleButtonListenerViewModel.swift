//
//  BleButtonListenerViewModel.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

import Foundation
import CoreBluetooth

final class BleButtonListenerViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var log: String = "🔌 初期化待ち"
    @Published var health: Int = 100 // ← 体力追加


    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var notifyCharacteristic: CBCharacteristic?

    private let targetServiceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    private let notifyCharacteristicUUID = CBUUID(string: "87654321-4321-4321-4321-CBA987654321")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            log.append("\n🔍 Bluetooth ON: スキャン開始")
            centralManager.scanForPeripherals(withServices: nil, options: nil) // UUID付きで検出できない場合は nil にする
        default:
            log.append("\n❌ Bluetooth未対応/無効（状態: \(central.state.rawValue)）")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("📡 発見: \(peripheral.name ?? "no name")")
        print("📦 Advertisement: \(advertisementData)")

        if let name = peripheral.name, name.contains("ESP32") {
            log.append("\n✅ 対象デバイス発見: \(name)")
            targetPeripheral = peripheral
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.append("\n🔗 接続成功")
        peripheral.delegate = self
        peripheral.discoverServices([targetServiceUUID])
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == targetServiceUUID {
                log.append("\n🧩 対象サービス発見")
                peripheral.discoverCharacteristics([notifyCharacteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == notifyCharacteristicUUID {
                log.append("\n📡 Notifyキャラクタリスティック発見")
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            let byteString = data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
            log.append("\n📥 通知受信（RAW）: \(byteString)")

            if let message = String(data: data, encoding: .utf8) {
                log.append("\n📥 通知受信（文字列）: \(message)")

                // 🔽 "button" を含むか確認して体力を減らす
                if message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().contains("button") {
                    if health > 0 {
                        health = max(0, health - 10)
                        log.append("\n💥 体力が減った！ 残り: \(health)")
                    }
                }
            } else {
                log.append("\n⚠️ UTF-8デコード失敗")
            }
        }
    }


}
