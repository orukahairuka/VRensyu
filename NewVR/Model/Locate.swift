//
//  Locate.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

import FirebaseFirestore
import CoreLocation

struct LocationData: Identifiable {
    let id: String  // userId
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

final class LocationRepository {
    private let db = Firestore.firestore()

    func updateLocation(userId: String, location: LocationData) {
        db.collection("locations").document(userId).setData([
            "latitude": location.latitude,
            "longitude": location.longitude,
            "timestamp": Timestamp(date: location.timestamp)
        ])
    }

    func observeLocations(completion: @escaping ([LocationData]) -> Void) {
        db.collection("locations").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }

            let results: [LocationData] = documents.compactMap { doc in
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

            completion(results)
        }
    }
}

