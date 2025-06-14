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
import SwiftUICore
import _MapKit_SwiftUI
import SwiftUI
import UIKit

final class MapLocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocations: [LocationData] = []
    @Published var region: MKCoordinateRegion? = nil
    private var hasSetInitialRegion = false

    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private let userId = UIDevice.persistentID
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


struct UserMapView: View {
    @ObservedObject var viewModel: MapLocationViewModel
    private let currentGroupCode = UserDefaults.standard.string(forKey: "groupCode") ?? "ABC123"

    var body: some View {
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
    }
}
