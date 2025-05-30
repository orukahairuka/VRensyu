//
//  LocationViewModel.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

import CoreLocation
import Combine
import UIKit


final class MapLocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocations: [LocationData] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.0, longitude: 135.0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

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
                      let ts = data["timestamp"] as? Timestamp else { return nil }

                return LocationData(
                    id: doc.documentID,
                    latitude: lat,
                    longitude: lon,
                    timestamp: ts.dateValue()
                )
            }

            DispatchQueue.main.async {
                self.userLocations = newLocations
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        // 自分の位置を Firestore に更新
        db.collection("locations").document(userId).setData([
            "latitude": loc.coordinate.latitude,
            "longitude": loc.coordinate.longitude,
            "timestamp": Timestamp(date: Date())
        ])

        // 地図の中心も更新
        DispatchQueue.main.async {
            self.region.center = loc.coordinate
        }
    }
}
