////
////  LocationRistView.swift
////  NewVR
////
////  Created by 櫻井絵理香 on 2025/05/30.
////
//
//import SwiftUI
//import MapKit
//
//struct UserMapView: View {
//    @StateObject private var viewModel = MapLocationViewModel()
//
//    var body: some View {
//        Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.userLocations) { location in
//            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
//                VStack {
//                    Image(systemName: "mappin.circle.fill")
//                        .resizable()
//                        .frame(width: 30, height: 30)
//                        .foregroundColor(.red)
//                    Text(location.id.prefix(6)) // ユーザーIDの一部
//                        .font(.caption)
//                        .foregroundColor(.black)
//                }
//            }
//        }
//        .edgesIgnoringSafeArea(.all)
//    }
//}
