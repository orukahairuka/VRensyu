// LocationData.swift
import Foundation

struct LocationData: Identifiable {
    let id: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let hp: Int
    let groupCode: String
    let isAlive: Bool
}


// MapLocationViewModel.swift
import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import MapKit

final class MapLocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocations: [LocationData] = []
    @Published var region: MKCoordinateRegion? = nil
    private var hasSetInitialRegion = false

    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private let groupCode: String = UserDefaults.standard.string(forKey: "groupCode") ?? "ABC123"
    @Published var health: Int = 100

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        observeLocations()
    }

    private func observeLocations() {
        db.collection("locations").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }

            let newLocations: [LocationData] = documents.compactMap { doc in
                let data = doc.data()
                guard let lat = data["latitude"] as? Double,
                      let lon = data["longitude"] as? Double,
                      let ts = data["timestamp"] as? Timestamp,
                      let hp = data["hp"] as? Int,
                      let groupCode = data["groupCode"] as? String,
                      let isAlive = data["isAlive"] as? Bool,
                      isAlive else { return nil }

                return LocationData(
                    id: doc.documentID,
                    latitude: lat,
                    longitude: lon,
                    timestamp: ts.dateValue(),
                    hp: hp,
                    groupCode: groupCode,
                    isAlive: isAlive
                )
            }

            DispatchQueue.main.async {
                self.userLocations = newLocations
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("🛰️ 位置情報更新された")
        guard let loc = locations.last else { return }

        db.collection("locations").document(userId).setData([
            "latitude": loc.coordinate.latitude,
            "longitude": loc.coordinate.longitude,
            "timestamp": Timestamp(date: Date()),
            "hp": health,
            "groupCode": groupCode,
            "isAlive": health > 0
        ]) { error in
            if let error = error {
                print("❌ Firestore書き込み失敗: \(error)")
            } else {
                print("✅ Firestore書き込み成功")
            }
        }

        if !hasSetInitialRegion {
            DispatchQueue.main.async {
                self.region = MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                self.hasSetInitialRegion = true
            }
        }
    }

    func updateHealth(_ newValue: Int) {
        self.health = max(0, newValue)
        if let location = locationManager.location {
            locationManager(locationManager, didUpdateLocations: [location])
        }
    }
}


// UserMapView.swift
import SwiftUI
import MapKit

struct UserMapView: View {
    @StateObject private var viewModel = MapLocationViewModel()
    @StateObject private var bleViewModel: BleButtonListenerViewModel
    private let currentGroupCode = UserDefaults.standard.string(forKey: "groupCode") ?? "ABC123"

    init() {
        let sharedMapVM = MapLocationViewModel()
        _viewModel = StateObject(wrappedValue: sharedMapVM)
        _bleViewModel = StateObject(wrappedValue: BleButtonListenerViewModel(mapViewModel: sharedMapVM))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let region = viewModel.region {
                Map(coordinateRegion: .constant(region), annotationItems: viewModel.userLocations) { location in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(location.groupCode == currentGroupCode ? .blue : .red)
                            Text(location.id.prefix(6))
                                .font(.caption)
                                .foregroundColor(.black)
                            Text("HP: \(location.hp)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                ProgressView("位置取得中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("📲 ESP32ボタン受信アプリ")
                    .font(.title)

                Text("❤️ 体力: \(viewModel.health)")
                ProgressView(value: Float(viewModel.health), total: 100)
                    .progressViewStyle(LinearProgressViewStyle())

                if viewModel.health == 0 {
                    Text("💀 ゲームオーバー")
                        .font(.title)
                        .foregroundColor(.red)
                        .bold()

                    Button(action: {
                        viewModel.updateHealth(100)
                        bleViewModel.log.append("\n🔁 体力を復活しました")
                    }) {
                        Text("🔁 もう一度")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                ScrollView {
                    Text(bleViewModel.log)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .padding()
        }
    }
}


// BleButtonListenerViewModel.swift
import Foundation
import CoreBluetooth

final class BleButtonListenerViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var log: String = "🔌 初期化待ち"
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var notifyCharacteristic: CBCharacteristic?

    private let targetServiceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    private let notifyCharacteristicUUID = CBUUID(string: "87654321-4321-4321-4321-CBA987654321")

    private let mapViewModel: MapLocationViewModel

    init(mapViewModel: MapLocationViewModel) {
        self.mapViewModel = mapViewModel
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            log.append("\n🔍 Bluetooth ON: スキャン開始")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        default:
            log.append("\n❌ Bluetooth未対応/無効（状態: \(central.state.rawValue)）")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, name == "ESP32 Button" {
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

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == targetServiceUUID {
            log.append("\n🧩 対象サービス発見")
            peripheral.discoverCharacteristics([notifyCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == notifyCharacteristicUUID {
            log.append("\n📡 Notifyキャラクタリスティック発見")
            notifyCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let byteString = data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
        log.append("\n📥 通知受信（RAW）: \(byteString)")

        if let message = String(data: data, encoding: .utf8) {
            log.append("\n📥 通知受信（文字列）: \(message)")

            if message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().contains("button") {
                if mapViewModel.health > 0 {
                    let newHealth = max(0, mapViewModel.health - 10)
                    mapViewModel.updateHealth(newHealth)
                    log.append("\n💥 体力が減った！ 残り: \(newHealth)")
                }
            }
        } else {
            log.append("\n⚠️ UTF-8デコード失敗")
        }
    }
}

