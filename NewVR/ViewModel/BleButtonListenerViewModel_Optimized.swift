import Foundation
import CoreBluetooth

final class BleButtonListenerViewModelOptimized: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var log: String = "🔌 初期化待ち"
    private weak var mapViewModel: MapLocationViewModel?
    @Published var health: Int = 300
    
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var notifyCharacteristic: CBCharacteristic?
    
    // 🔧 UUIDを後から決定
    private var targetServiceUUID: CBUUID!
    private var notifyCharacteristicUUID: CBUUID!
    private var targetDeviceName: String = ""
    
    // 🚀 高速化のための追加プロパティ
    private var lastConnectedDeviceUUID: String? {
        get { UserDefaults.standard.string(forKey: "lastConnectedESP32UUID") }
        set { UserDefaults.standard.set(newValue, forKey: "lastConnectedESP32UUID") }
    }
    private var scanTimer: Timer?
    private let scanTimeout: TimeInterval = 3.0
    private var discoveredPeripherals: [CBPeripheral] = []
    
    override init() {
        super.init()
        setupUUID()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    init(mapViewModel: MapLocationViewModel) {
        self.mapViewModel = mapViewModel
        super.init()
        setupUUID()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// 🔄 ユーザー名の末尾によってUUIDを切り替える
    private func setupUUID() {
        let username = UserDefaults.standard.string(forKey: "username") ?? ""
        let userSuffix = username.suffix(1)
        
        print("🧩 setupUUID(): username = \(username), suffix = \(userSuffix)")
        
        if userSuffix == "2" {
            targetServiceUUID = CBUUID(string: "12345678-0002-0002-0002-123456789ABC")
            notifyCharacteristicUUID = CBUUID(string: "87654321-0002-0002-0002-CBA987654321")
            targetDeviceName = "ESP32 IR Button 2"
        } else if userSuffix == "1" {
            targetServiceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
            notifyCharacteristicUUID = CBUUID(string: "87654321-4321-4321-4321-CBA987654321")
            targetDeviceName = "ESP32 IR Button 1"
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("\n🔍 Bluetooth ON: スキャン開始")
            setupUUID()
            startOptimizedScan()
        default:
            print("\n❌ Bluetooth未対応/無効（状態: \(central.state.rawValue)）")
        }
    }
    
    /// 🚀 最適化されたスキャン開始
    private func startOptimizedScan() {
        // 1. 既知のデバイスがあれば先に接続を試みる
        if let lastUUID = lastConnectedDeviceUUID,
           let uuid = UUID(uuidString: lastUUID) {
            print("🎯 前回接続したデバイスを優先的に探しています: \(lastUUID)")
            
            let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
            if let peripheral = knownPeripherals.first {
                print("✨ 既知のデバイスが見つかりました！即座に接続を試みます")
                connectTo(peripheral)
                return
            }
        }
        
        // 2. サービスUUIDでフィルタリングしてスキャン（高速化）
        let scanOptions: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true  // 重複を許可してより早く発見
        ]
        
        // 特定のサービスUUIDを持つデバイスのみスキャン
        centralManager.scanForPeripherals(
            withServices: [targetServiceUUID],
            options: scanOptions
        )
        
        // 3. タイムアウト設定
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanTimeout, repeats: false) { _ in
            print("⏱️ スキャンタイムアウト - 全デバイススキャンに切り替えます")
            self.fallbackToFullScan()
        }
        
        DispatchQueue.main.async {
            self.log = "🔍 \(self.targetDeviceName)を高速検索中..."
        }
    }
    
    /// 🔄 フォールバック: 全デバイススキャン
    private func fallbackToFullScan() {
        centralManager.stopScan()
        
        print("🔍 フルスキャンモードに切り替えました")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        
        DispatchQueue.main.async {
            self.log = "🔍 全デバイスから\(self.targetDeviceName)を検索中..."
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // RSSI（信号強度）でフィルタリング - 近いデバイスを優先
        let rssiValue = RSSI.intValue
        if rssiValue < -80 && rssiValue != 127 {  // 127は測定不能を意味する
            print("📡 信号が弱いデバイスをスキップ: \(peripheral.name ?? "no name") (RSSI: \(rssiValue))")
            return
        }
        
        print("📡 発見: \(peripheral.name ?? "no name") (RSSI: \(rssiValue))")
        
        // デバイス名で高速判定
        if let deviceName = peripheral.name,
           deviceName == targetDeviceName {
            print("🎯 ターゲットデバイスを即座に発見！")
            connectTo(peripheral)
            return
        }
        
        // 広告データでの判定（フォールバック）
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
           localName == targetDeviceName {
            print("🎯 広告データからターゲットデバイスを発見！")
            connectTo(peripheral)
        }
    }
    
    private func connectTo(_ peripheral: CBPeripheral) {
        print("✅ 対象デバイス発見: \(peripheral.name ?? "no name")")
        
        // タイマーをキャンセル
        scanTimer?.invalidate()
        scanTimer = nil
        
        targetPeripheral = peripheral
        centralManager.stopScan()
        
        // デバイスUUIDを保存
        lastConnectedDeviceUUID = peripheral.identifier.uuidString
        
        centralManager.connect(peripheral, options: nil)
        
        DispatchQueue.main.async {
            self.log = "🔗 \(peripheral.name ?? "デバイス")に接続中..."
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\n🔗 接続成功: \(peripheral.name ?? "no name")")
        
        DispatchQueue.main.async {
            self.log = "✅ \(peripheral.name ?? "デバイス")に接続完了！"
        }
        
        peripheral.delegate = self
        peripheral.discoverServices([targetServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ 接続失敗: \(error?.localizedDescription ?? "unknown error")")
        
        // 保存されたUUIDをクリア
        lastConnectedDeviceUUID = nil
        
        // 再スキャン
        startOptimizedScan()
        
        DispatchQueue.main.async {
            self.log = "❌ 接続失敗。再スキャン中..."
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 切断: \(peripheral.name ?? "no name")")
        
        DispatchQueue.main.async {
            self.log = "🔌 切断されました。再接続を試みます..."
        }
        
        // 自動再接続
        centralManager.connect(peripheral, options: nil)
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
            
            DispatchQueue.main.async {
                self.log = "🎮 準備完了！ボタン入力を待っています..."
            }
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
                    
                    DispatchQueue.main.async {
                        self.log = "💥 ダメージ受信！ HP: \(newHealth)/300"
                    }
                }
            }
        } else {
            print("\n⚠️ UTF-8デコード失敗")
        }
    }
}