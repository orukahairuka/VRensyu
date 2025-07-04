import Foundation
import UIKit
import CoreLocation
import MapKit
import FirebaseFirestore
import Combine

/// ゲーム設定管理
struct GameConfiguration {
    static let shared = GameConfiguration()
    
    // MARK: - Player Limits
    let maxPlayersPerTeam: Int = 10
    let maxTotalPlayers: Int = 20
    let minPlayersToStart: Int = 2
    
    // MARK: - Map Display Settings
    let radarRange: Double = 100.0 // メートル
    let enemyDisplayDelay: TimeInterval = 30.0 // 秒
    let mapUpdateInterval: TimeInterval = 1.0 // 秒
    
    // MARK: - Team Management
    let supportedTeamCodes = ["RED", "BLUE", "GREEN", "YELLOW", "ORANGE"]
    
    private init() {}
}

/// 拡張されたチーム管理
class TeamManager: ObservableObject {
    @Published var teams: [Team] = []
    @Published var currentTeam: Team?
    
    private let maxPlayersPerTeam = GameConfiguration.shared.maxPlayersPerTeam
    
    struct Team: Identifiable, Hashable {
        let id = UUID()
        let code: String
        let name: String
        let color: TeamColor
        var players: [Player] = []
        
        var isFull: Bool {
            players.count >= GameConfiguration.shared.maxPlayersPerTeam
        }
        
        enum TeamColor: CaseIterable {
            case red, blue, green, yellow, orange
            
            var uiColor: UIColor {
                switch self {
                case .red: return .systemRed
                case .blue: return .systemBlue
                case .green: return .systemGreen
                case .yellow: return .systemYellow
                case .orange: return .systemOrange
                }
            }
            
            var name: String {
                switch self {
                case .red: return "レッドチーム"
                case .blue: return "ブルーチーム"
                case .green: return "グリーンチーム"
                case .yellow: return "イエローチーム"
                case .orange: return "オレンジチーム"
                }
            }
        }
    }
    
    struct Player: Identifiable, Hashable {
        let id: String
        let username: String
        let deviceNumber: Int
        var isOnline: Bool = false
        var health: Int = 300
        var lastSeen: Date = Date()
    }
    
    init() {
        setupDefaultTeams()
    }
    
    private func setupDefaultTeams() {
        teams = [
            Team(code: "RED", name: "レッドチーム", color: .red),
            Team(code: "BLUE", name: "ブルーチーム", color: .blue),
            Team(code: "GREEN", name: "グリーンチーム", color: .green),
            Team(code: "YELLOW", name: "イエローチーム", color: .yellow),
            Team(code: "ORANGE", name: "オレンジチーム", color: .orange)
        ]
    }
    
    func joinTeam(code: String, player: Player) -> Bool {
        guard let teamIndex = teams.firstIndex(where: { $0.code == code }),
              !teams[teamIndex].isFull else {
            return false
        }
        
        // 他のチームから削除
        leaveCurrentTeam(player: player)
        
        // 新しいチームに追加
        teams[teamIndex].players.append(player)
        currentTeam = teams[teamIndex]
        
        return true
    }
    
    func leaveCurrentTeam(player: Player) {
        for i in teams.indices {
            teams[i].players.removeAll { $0.id == player.id }
        }
    }
    
    func getAvailableTeams() -> [Team] {
        return teams.filter { !$0.isFull }
    }
}

/// パフォーマンス最適化のためのキャッシュマネージャー
class LocationCacheManager {
    private var locationCache: [String: LocationData] = [:]
    private var lastUpdate: [String: Date] = [:]
    private let cacheTimeout: TimeInterval = 60.0 // 1分
    
    func updateLocation(_ location: LocationData) {
        locationCache[location.id] = location
        lastUpdate[location.id] = Date()
    }
    
    func getLocations(for teamCode: String) -> [LocationData] {
        let currentTime = Date()
        
        // 期限切れのキャッシュを削除
        cleanExpiredCache(currentTime: currentTime)
        
        return locationCache.values
            .filter { $0.groupCode == teamCode }
            .filter { $0.isAlive }
    }
    
    func getAllLocations() -> [LocationData] {
        let currentTime = Date()
        cleanExpiredCache(currentTime: currentTime)
        
        return Array(locationCache.values)
            .filter { $0.isAlive }
    }
    
    private func cleanExpiredCache(currentTime: Date) {
        let expiredKeys = lastUpdate.compactMap { key, time in
            currentTime.timeIntervalSince(time) > cacheTimeout ? key : nil
        }
        
        for key in expiredKeys {
            locationCache.removeValue(forKey: key)
            lastUpdate.removeValue(forKey: key)
        }
    }
}

/// スケーラブルなMapLocationViewModel
final class ScalableMapLocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, HealthManagerProtocol {
    @Published var userLocations: [EnhancedLocationData] = []
    @Published var region: MKCoordinateRegion? = nil
    @Published var displayMode: MapDisplayMode = .teammateOnly
    @Published var selectedTeam: TeamManager.Team?
    
    private var hasSetInitialRegion = false
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private let teamManager = TeamManager()
    private let cacheManager = LocationCacheManager()
    
    private var username: String {
        UserDefaults.standard.string(forKey: "username") ?? "Unknown"
    }
    
    private var groupCode: String {
        selectedTeam?.code ?? UserDefaults.standard.string(forKey: "groupCode") ?? "BLUE"
    }
    
    @Published var health: Int = 300
    
    // Firebase リスナーの管理
    private var locationListener: ListenerRegistration?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // デフォルトチームの設定
        if let defaultTeam = teamManager.teams.first {
            selectedTeam = defaultTeam
        }
        
        startLocationObserver()
    }
    
    deinit {
        locationListener?.remove()
    }
    
    func selectTeam(_ team: TeamManager.Team) {
        selectedTeam = team
        UserDefaults.standard.set(team.code, forKey: "groupCode")
        refreshLocationDisplay()
    }
    
    private func startLocationObserver() {
        // より効率的なクエリ（チーム別でフィルタリング）
        locationListener = db.collection("locations")
            .whereField("isAlive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents else { return }
                
                self.processLocationUpdates(documents)
            }
    }
    
    private func processLocationUpdates(_ documents: [QueryDocumentSnapshot]) {
        let locations: [LocationData] = documents.compactMap { doc in
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
        
        // キャッシュを更新
        for location in locations {
            cacheManager.updateLocation(location)
        }
        
        refreshLocationDisplay()
    }
    
    private func refreshLocationDisplay() {
        guard let team = selectedTeam else { return }
        
        var displayLocations: [EnhancedLocationData] = []
        
        switch displayMode {
        case .teammateOnly:
            let teammates = cacheManager.getLocations(for: team.code)
            displayLocations = teammates.map {
                EnhancedLocationData(from: $0, currentGroupCode: team.code, delayed: false)
            }
            
        case .teammateWithDelayed:
            let teammates = cacheManager.getLocations(for: team.code)
            displayLocations.append(contentsOf: teammates.map {
                EnhancedLocationData(from: $0, currentGroupCode: team.code, delayed: false)
            })
            
            let currentTime = Date()
            let allLocations = cacheManager.getAllLocations()
            let delayedEnemies = allLocations
                .filter { $0.groupCode != team.code }
                .filter { currentTime.timeIntervalSince($0.timestamp) >= GameConfiguration.shared.enemyDisplayDelay }
            
            displayLocations.append(contentsOf: delayedEnemies.map {
                EnhancedLocationData(from: $0, currentGroupCode: team.code, delayed: true)
            })
            
        case .teammateWithRadar:
            let teammates = cacheManager.getLocations(for: team.code)
            displayLocations.append(contentsOf: teammates.map {
                EnhancedLocationData(from: $0, currentGroupCode: team.code, delayed: false)
            })
            
            guard let userLocation = locationManager.location else { break }
            
            let allLocations = cacheManager.getAllLocations()
            let nearbyEnemies = allLocations
                .filter { $0.groupCode != team.code }
                .filter { enemy in
                    let enemyLocation = CLLocation(latitude: enemy.latitude, longitude: enemy.longitude)
                    return userLocation.distance(from: enemyLocation) <= GameConfiguration.shared.radarRange
                }
            
            displayLocations.append(contentsOf: nearbyEnemies.map {
                EnhancedLocationData(from: $0, currentGroupCode: team.code, delayed: false)
            })
        }
        
        DispatchQueue.main.async {
            self.userLocations = displayLocations
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last,
              let team = selectedTeam else { return }
        
        db.collection("locations").document(userId).setData([
            "userId": userId,
            "username": username,
            "latitude": loc.coordinate.latitude,
            "longitude": loc.coordinate.longitude,
            "timestamp": Timestamp(date: Date()),
            "hp": health,
            "groupCode": team.code,
            "isAlive": health > 0,
            "teamName": team.name
        ]) { error in
            if let error = error {
                print("❌ Firestore書き込み失敗: \(error)")
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