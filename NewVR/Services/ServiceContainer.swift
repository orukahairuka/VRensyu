import Foundation

/// 依存性注入コンテナ
final class ServiceContainer {
    static let shared = ServiceContainer()
    
    // MARK: - Services
    private(set) lazy var bleService: BLEServiceProtocol = {
        BLEService(configuration: .default)
    }()
    
    // MARK: - ViewModels Factory
    func makeBleViewModel(healthManager: HealthManagerProtocol? = nil) -> BleViewModel {
        let viewModel = BleViewModel(
            bleService: bleService,
            healthManager: healthManager,
            deviceNumberProvider: UserDeviceNumberProvider()
        )
        return viewModel
    }
    
    private init() {}
}

/// ユーザー設定からデバイス番号を取得
struct UserDeviceNumberProvider: DeviceNumberProvider {
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