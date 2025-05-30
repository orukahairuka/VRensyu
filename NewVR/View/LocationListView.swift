//
//  LocationRistView.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

import SwiftUI

struct LocationListView: View {
    @StateObject private var viewModel = LocationViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.allLocations) { loc in
                VStack(alignment: .leading) {
                    Text("🆔 \(loc.id.prefix(6))…")
                    Text("📍 緯度: \(loc.latitude), 経度: \(loc.longitude)")
                    Text("🕒 \(loc.timestamp.formatted())")
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("ユーザー位置一覧")
        }
    }
}
