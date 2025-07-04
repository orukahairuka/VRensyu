import Foundation
import CoreLocation
import MapKit
import Combine

/// MapLocationViewModelにHealthManagerProtocolを実装
extension MapLocationViewModel: HealthManagerProtocol {
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