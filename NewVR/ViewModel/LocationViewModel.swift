//
//  LocationViewModel.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

import CoreLocation
import Combine
import UIKit

final class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var allLocations: [LocationData] = []

    private let locationManager = CLLocationManager()
    private let repository = LocationRepository()
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        repository.observeLocations { [weak self] locations in
            DispatchQueue.main.async {
                self?.allLocations = locations
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        let locationData = LocationData(
            id: userId,
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            timestamp: Date()
        )
        repository.updateLocation(userId: userId, location: locationData)
    }
}
