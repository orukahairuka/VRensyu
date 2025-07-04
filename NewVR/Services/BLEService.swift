import Foundation
import CoreBluetooth
import Combine

/// BLE通信を管理するサービスクラス
final class BLEService: NSObject, BLEServiceProtocol {
    
    // MARK: - Published Properties
    let connectionState = CurrentValueSubject<BLEConnectionState, Never>(.disconnected)
    let discoveredDevices = CurrentValueSubject<[BLEDevice], Never>([])
    let connectedDevice = CurrentValueSubject<BLEDevice?, Never>(nil)
    let buttonEvents = PassthroughSubject<ButtonEvent, Never>()
    let errors = PassthroughSubject<BLEError, Never>()
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var notifyCharacteristic: CBCharacteristic?
    private let configuration: BLEConfiguration
    
    private var targetDeviceNumber: Int?
    private var targetServiceUUID: CBUUID?
    private var targetCharacteristicUUID: CBUUID?
    
    private var scanTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UserDefaults Keys
    private let lastConnectedDeviceKey = "lastConnectedESP32UUID"
    
    // MARK: - Initialization
    init(configuration: BLEConfiguration = .default) {
        self.configuration = configuration
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    func startScanning(for deviceNumber: Int) {
        guard centralManager.state == .poweredOn else {
            errors.send(.bluetoothNotAvailable)
            return
        }
        
        targetDeviceNumber = deviceNumber
        targetServiceUUID = configuration.serviceUUID(for: deviceNumber)
        targetCharacteristicUUID = configuration.characteristicUUID(for: deviceNumber)
        
        guard targetServiceUUID != nil, targetCharacteristicUUID != nil else {
            errors.send(.invalidDeviceNumber)
            return
        }
        
        connectionState.send(.scanning)
        discoveredDevices.send([])
        
        // 既知のデバイスを優先的に探す
        if let lastDeviceUUID = UserDefaults.standard.string(forKey: lastConnectedDeviceKey),
           let uuid = UUID(uuidString: lastDeviceUUID) {
            attemptReconnection(to: uuid)
        } else {
            performOptimizedScan()
        }
    }
    
    func stopScanning() {
        scanTimer?.invalidate()
        scanTimer = nil
        centralManager.stopScan()
        
        if connectionState.value == .scanning {
            connectionState.send(.disconnected)
        }
    }
    
    func connect(to device: BLEDevice) {
        stopScanning()
        connectionState.send(.connecting)
        
        targetPeripheral = device.peripheral
        centralManager.connect(device.peripheral, options: nil)
        
        // デバイスUUIDを保存
        UserDefaults.standard.set(device.id.uuidString, forKey: lastConnectedDeviceKey)
    }
    
    func disconnect() {
        if let peripheral = targetPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        targetPeripheral = nil
        notifyCharacteristic = nil
        connectedDevice.send(nil)
        connectionState.send(.disconnected)
    }
    
    func reconnectToLastDevice() {
        guard let lastDeviceUUID = UserDefaults.standard.string(forKey: lastConnectedDeviceKey),
              let uuid = UUID(uuidString: lastDeviceUUID),
              let deviceNumber = targetDeviceNumber else {
            startScanning(for: targetDeviceNumber ?? 1)
            return
        }
        
        startScanning(for: deviceNumber)
    }
    
    // MARK: - Private Methods
    private func attemptReconnection(to uuid: UUID) {
        let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        
        if let peripheral = knownPeripherals.first {
            print("✨ 既知のデバイスが見つかりました")
            let device = BLEDevice(
                id: peripheral.identifier,
                name: peripheral.name ?? "Unknown Device",
                peripheral: peripheral,
                rssi: -50, // デフォルト値
                lastSeen: Date()
            )
            connect(to: device)
        } else {
            performOptimizedScan()
        }
    }
    
    private func performOptimizedScan() {
        guard let serviceUUID = targetServiceUUID else { return }
        
        // サービスUUIDでフィルタリング（高速スキャン）
        let scanOptions: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: configuration.allowDuplicates
        ]
        
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: scanOptions
        )
        
        // タイムアウト設定
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.scanTimeout,
            repeats: false
        ) { [weak self] _ in
            self?.fallbackToFullScan()
        }
    }
    
    private func fallbackToFullScan() {
        print("⏱️ フルスキャンモードに切り替え")
        centralManager.stopScan()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    private func processDiscoveredPeripheral(_ peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        // 信号強度フィルタリング
        let rssiValue = rssi.intValue
        if rssiValue < configuration.rssiThreshold && rssiValue != 127 {
            return
        }
        
        // デバイス名の取得
        let deviceName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        
        let device = BLEDevice(
            id: peripheral.identifier,
            name: deviceName,
            peripheral: peripheral,
            rssi: rssiValue,
            lastSeen: Date()
        )
        
        // デバイスリストを更新
        var devices = discoveredDevices.value
        devices.removeAll { $0.id == device.id }
        devices.append(device)
        discoveredDevices.send(devices)
        
        // ターゲットデバイスかチェック
        if device.isTargetDevice,
           device.deviceNumber == targetDeviceNumber {
            connect(to: device)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("🔍 Bluetooth ON")
            // 自動再接続が有効な場合
            if configuration.autoReconnect,
               connectionState.value == .disconnected,
               targetDeviceNumber != nil {
                reconnectToLastDevice()
            }
        case .poweredOff:
            errors.send(.bluetoothNotAvailable)
            connectionState.send(.disconnected)
        default:
            print("❌ Bluetooth状態: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        processDiscoveredPeripheral(peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("🔗 接続成功: \(peripheral.name ?? "Unknown")")
        
        scanTimer?.invalidate()
        targetPeripheral = peripheral
        peripheral.delegate = self
        
        connectionState.send(.connected)
        
        // サービス探索
        if let serviceUUID = targetServiceUUID {
            peripheral.discoverServices([serviceUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ 接続失敗: \(error?.localizedDescription ?? "Unknown error")")
        
        errors.send(.connectionFailed(error?.localizedDescription ?? "Unknown error"))
        connectionState.send(.disconnected)
        
        // 自動再試行
        if configuration.autoReconnect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.reconnectToLastDevice()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 切断: \(peripheral.name ?? "Unknown")")
        
        targetPeripheral = nil
        notifyCharacteristic = nil
        connectedDevice.send(nil)
        connectionState.send(.disconnected)
        
        // 自動再接続
        if configuration.autoReconnect, error != nil {
            reconnectToLastDevice()
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services,
              let targetUUID = targetServiceUUID else {
            errors.send(.serviceNotFound)
            return
        }
        
        for service in services where service.uuid == targetUUID {
            print("🧩 対象サービス発見")
            if let characteristicUUID = targetCharacteristicUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics,
              let targetUUID = targetCharacteristicUUID else {
            errors.send(.characteristicNotFound)
            return
        }
        
        for characteristic in characteristics where characteristic.uuid == targetUUID {
            print("📡 Notifyキャラクタリスティック発見")
            notifyCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
            
            // 完全に準備完了
            connectionState.send(.ready)
            
            // 接続デバイス情報を更新
            if let device = discoveredDevices.value.first(where: { $0.peripheral == peripheral }) {
                connectedDevice.send(device)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        let event = ButtonEvent(
            timestamp: Date(),
            deviceId: peripheral.identifier,
            rawData: data,
            message: String(data: data, encoding: .utf8)
        )
        
        if event.isValidButtonPress {
            buttonEvents.send(event)
        }
    }
}