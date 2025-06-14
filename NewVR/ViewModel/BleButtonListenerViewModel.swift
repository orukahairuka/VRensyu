//
//  BleButtonListenerViewModel.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

// BleButtonListenerViewModel.swift
// 修正内容: `mapViewModel` のオプショナルを安全に unwrap

import Foundation
import CoreBluetooth

final class BleButtonListenerViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var log: String = "🔌 初期化待ち"
    private weak var mapViewModel: MapLocationViewModel?
    @Published var health: Int = 100

    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var notifyCharacteristic: CBCharacteristic?

    private let targetServiceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    private let notifyCharacteristicUUID = CBUUID(string: "87654321-4321-4321-4321-CBA987654321")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    init(mapViewModel: MapLocationViewModel) {
        self.mapViewModel = mapViewModel
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("\n🔍 Bluetooth ON: スキャン開始")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        default:
            print("\n❌ Bluetooth未対応/無効（状態: \(central.state.rawValue)）")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("📡 発見: \(peripheral.identifier)")
        print("📛 名前: \(peripheral.name ?? "no name")")
        print("📦 advertisementData: \(advertisementData)")

        // この if は一時的に外してみてもよい
        if let name = peripheral.name, name.contains("ESP32") {
            print("✅ 対象デバイス発見: \(name)")
            targetPeripheral = peripheral
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
        }
    }


    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\n🔗 接続成功")
        print("🔗 接続成功: \(peripheral.name ?? "no name")") // ✅ 追加ログ
        peripheral.delegate = self
        peripheral.discoverServices([targetServiceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == targetServiceUUID {
            print("\n🧩 対象サービス発見")
            peripheral.discoverCharacteristics([notifyCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == notifyCharacteristicUUID {
            print("\n📡 Notifyキャラクタリスティック発見")
            notifyCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let byteString = data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
        print("\n📥 通知受信（RAW）: \(byteString)")

        if let message = String(data: data, encoding: .utf8) {
            print("\n📥 通知受信（文字列）: \(message)")

            if message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().contains("button") {
                if let vm = mapViewModel, vm.health > 0 {
                    let newHealth = max(0, vm.health - 10)
                    vm.updateHealth(newHealth)
                    print("\n💥 体力が減った！ 残り: \(newHealth)")
                }
            }
        } else {
            print("\n⚠️ UTF-8デコード失敗")
        }
    }
}
