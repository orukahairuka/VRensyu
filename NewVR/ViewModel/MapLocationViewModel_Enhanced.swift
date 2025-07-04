// MapLocationViewModel_Enhanced.swift
import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import MapKit
import SwiftUICore
import _MapKit_SwiftUI
import SwiftUI
import UIKit

/// 拡張されたLocationData（敵チーム遅延表示対応）
struct EnhancedLocationData: Identifiable {
    let id: String
    let username: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let hp: Int
    let groupCode: String
    let isAlive: Bool
    let isTeammate: Bool
    let isDelayed: Bool // 遅延表示フラグ
    
    init(from locationData: LocationData, currentGroupCode: String, delayed: Bool = false) {
        self.id = locationData.id
        self.username = locationData.username
        self.latitude = locationData.latitude
        self.longitude = locationData.longitude
        self.timestamp = locationData.timestamp
        self.hp = locationData.hp
        self.groupCode = locationData.groupCode
        self.isAlive = locationData.isAlive
        self.isTeammate = locationData.groupCode == currentGroupCode
        self.isDelayed = delayed
    }
}

/// 表示モード列挙型
enum MapDisplayMode: CaseIterable {
    case teammateOnly       // 味方のみ
    case teammateWithDelayed // 味方 + 敵の遅延表示
    case teammateWithRadar  // 味方 + 範囲内の敵
    
    var description: String {
        switch self {
        case .teammateOnly:
            return "味方のみ"
        case .teammateWithDelayed:
            return "味方 + 敵(遅延)"
        case .teammateWithRadar:
            return "味方 + レーダー"
        }
    }
}

final class MapLocationViewModelEnhanced: NSObject, ObservableObject, CLLocationManagerDelegate, HealthManagerProtocol {
    @Published var userLocations: [EnhancedLocationData] = []
    @Published var region: MKCoordinateRegion? = nil
    @Published var displayMode: MapDisplayMode = .teammateOnly
    
    private var hasSetInitialRegion = false
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private let groupCode: String = UserDefaults.standard.string(forKey: "groupCode") ?? "ABC123"
    private var username: String {
        UserDefaults.standard.string(forKey: "username") ?? "Unknown"
    }
    
    @Published var health: Int = 300
    
    // 敵チームの遅延表示用キャッシュ
    private var enemyLocationCache: [String: LocationData] = [:]
    private let enemyDisplayDelay: TimeInterval = 30.0 // 30秒遅延
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        observeLocations()
    }
    
    func setDisplayMode(_ mode: MapDisplayMode) {
        displayMode = mode
        refreshLocationDisplay()
    }
    
    private func observeLocations() {
        db.collection("locations").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self,
                  let documents = snapshot?.documents else { return }
            
            let allLocations: [LocationData] = documents.compactMap { doc in
                let data = doc.data()
                guard let username = data["username"] as? String,
                      let lat = data["latitude"] as? Double,
                      let lon = data["longitude"] as? Double,
                      let ts = data["timestamp"] as? Timestamp,
                      let hp = data["hp"] as? Int,
                      let groupCode = data["groupCode"] as? String,
                      let isAlive = data["isAlive"] as? Bool,
                      isAlive else { return nil }
                
                return LocationData(
                    id: doc.documentID,
                    username: username,
                    latitude: lat,
                    longitude: lon,
                    timestamp: ts.dateValue(),
                    hp: hp,
                    groupCode: groupCode,
                    isAlive: isAlive
                )
            }
            
            self.processLocations(allLocations)
        }
    }
    
    private func processLocations(_ locations: [LocationData]) {
        // 味方と敵を分離
        let teammates = locations.filter { $0.groupCode == groupCode }
        let enemies = locations.filter { $0.groupCode != groupCode }
        
        // 敵チームの位置をキャッシュに保存
        for enemy in enemies {
            enemyLocationCache[enemy.id] = enemy
        }
        
        refreshLocationDisplay()
    }
    
    private func refreshLocationDisplay() {
        var displayLocations: [EnhancedLocationData] = []
        
        // 味方チーム（常に表示）
        let teammates = enemyLocationCache.values.filter { $0.groupCode == groupCode }
        displayLocations.append(contentsOf: teammates.map { 
            EnhancedLocationData(from: $0, currentGroupCode: groupCode, delayed: false)
        })
        
        // 表示モードに応じて敵チームを追加
        switch displayMode {
        case .teammateOnly:
            break // 味方のみ
            
        case .teammateWithDelayed:
            let currentTime = Date()
            let delayedEnemies = enemyLocationCache.values
                .filter { $0.groupCode != groupCode }
                .filter { currentTime.timeIntervalSince($0.timestamp) >= enemyDisplayDelay }
            
            displayLocations.append(contentsOf: delayedEnemies.map {
                EnhancedLocationData(from: $0, currentGroupCode: groupCode, delayed: true)
            })
            
        case .teammateWithRadar:
            // 範囲内の敵チームを表示（レーダー機能）
            guard let userLocation = locationManager.location else { break }
            
            let radarRange: CLLocationDistance = 100.0 // 100メートル範囲
            let nearbyEnemies = enemyLocationCache.values
                .filter { $0.groupCode != groupCode }
                .filter { enemy in
                    let enemyLocation = CLLocation(latitude: enemy.latitude, longitude: enemy.longitude)
                    return userLocation.distance(from: enemyLocation) <= radarRange
                }
            
            displayLocations.append(contentsOf: nearbyEnemies.map {
                EnhancedLocationData(from: $0, currentGroupCode: groupCode, delayed: false)
            })
        }
        
        DispatchQueue.main.async {
            self.userLocations = displayLocations
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("🛰️ 位置情報更新された")
        guard let loc = locations.last else { return }
        
        db.collection("locations").document(userId).setData([
            "userId": userId,
            "username": username,
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
                    span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
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
    
    // MARK: - HealthManagerProtocol Implementation
    var currentHealth: Int {
        return health
    }
    
    func takeDamage(_ amount: Int) {
        let newHealth = max(0, health - amount)
        updateHealth(newHealth)
    }
    
    func resetHealth() {
        updateHealth(300)
    }
}

// MARK: - Enhanced UserMapView
struct EnhancedUserMapView: View {
    @ObservedObject var viewModel: MapLocationViewModelEnhanced
    
    var body: some View {
        VStack {
            // 表示モード切り替え
            displayModeSelector
            
            // 統計情報
            statisticsView
            
            if let region = viewModel.region {
                Map(coordinateRegion: .constant(region), annotationItems: viewModel.userLocations) { location in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                        PlayerMarkerView(location: location)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    // レーダー範囲表示
                    radarOverlay,
                    alignment: .center
                )
            } else {
                ProgressView("位置取得中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var displayModeSelector: some View {
        HStack {
            Text("表示モード:")
                .font(.caption)
            
            Picker("表示モード", selection: $viewModel.displayMode) {
                ForEach(MapDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.description).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }
    
    private var statisticsView: some View {
        HStack {
            let teammates = viewModel.userLocations.filter { $0.isTeammate }
            let enemies = viewModel.userLocations.filter { !$0.isTeammate }
            
            Label("\(teammates.count)", systemImage: "person.fill")
                .foregroundColor(.blue)
            
            Spacer()
            
            if viewModel.displayMode != .teammateOnly {
                Label("\(enemies.count)", systemImage: "person.fill")
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            if viewModel.displayMode == .teammateWithRadar {
                Text("📡 100m範囲")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
        .font(.caption)
    }
    
    @ViewBuilder
    private var radarOverlay: some View {
        if viewModel.displayMode == .teammateWithRadar {
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                .frame(width: 200, height: 200) // UIでの表示サイズ
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Player Marker View
struct PlayerMarkerView: View {
    let location: EnhancedLocationData
    
    private var markerColor: Color {
        if location.isTeammate {
            return .blue
        } else if location.isDelayed {
            return .orange
        } else {
            return .red
        }
    }
    
    private var markerOpacity: Double {
        location.isDelayed ? 0.6 : 1.0
    }
    
    var body: some View {
        VStack {
            Image(systemName: location.isDelayed ? "mappin.circle" : "mappin.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(markerColor)
                .opacity(markerOpacity)
            
            Text(location.username.prefix(8))
                .font(.caption)
                .foregroundColor(.black)
            
            Text("HP: \(location.hp)")
                .font(.caption2)
                .foregroundColor(.gray)
            
            if location.isDelayed {
                Text("🕐 遅延")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
}