// LocationData.swift
import Foundation


struct LocationData: Identifiable {
    let id: String
    let username: String
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
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private let groupCode: String = UserDefaults.standard.string(forKey: "groupCode") ?? "ABC123"
    private var username: String {
        UserDefaults.standard.string(forKey: "username") ?? "Unknown"
    }

    @Published var health: Int = 300

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
                guard let username = data["username"] as? String,
                      let lat = data["latitude"] as? Double,
                      let lon = data["longitude"] as? Double,
                      let ts = data["timestamp"] as? Timestamp,
                      let hp = data["hp"] as? Int,
                      let groupCode = data["groupCode"] as? String,
                      let isAlive = data["isAlive"] as? Bool,
                      isAlive,
                      groupCode == self.groupCode else { return nil } // 🔒 味方チームのみフィルタリング

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

            DispatchQueue.main.async {
                self.userLocations = newLocations
            }
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
                    span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001) // 👈 ズームイン
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



import SwiftUI
import MapKit

struct UserMapView: View {
    @ObservedObject var viewModel: MapLocationViewModel

    var body: some View {
        if let region = viewModel.region {
            Map(coordinateRegion: .constant(region), annotationItems: viewModel.userLocations) { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue) // 🔒 味方チームのみなので常に青色
                        Text(location.username.prefix(8))
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
