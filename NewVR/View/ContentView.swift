//
//  ContentView.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/06/13.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var mapViewModel = MapLocationViewModel()
    @StateObject private var bleViewModel: BleButtonListenerViewModel

    init() {
        let mapVM = MapLocationViewModel()
        _mapViewModel = StateObject(wrappedValue: mapVM)
        _bleViewModel = StateObject(wrappedValue: BleButtonListenerViewModel(mapViewModel: mapVM))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("📲 ESP32ボタン受信アプリ")
                .font(.title)

            VStack(alignment: .leading, spacing: 10) {
                Text("❤️ 体力: \(mapViewModel.health)")
                ProgressView(value: Float(mapViewModel.health), total: 100)
                    .progressViewStyle(LinearProgressViewStyle())

                if mapViewModel.health == 0 {
                    Text("💀 ゲームオーバー")
                        .font(.title)
                        .foregroundColor(.red)
                        .bold()

                    Button(action: {
                        mapViewModel.updateHealth(100)
                        bleViewModel.log.append("\n🔁 体力を復活しました")
                    }) {
                        Text("🔁 もう一度")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }

            UserMapView(viewModel: mapViewModel) // ✅ 追加：マップ表示

            ScrollView {
                Text(bleViewModel.log)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .font(.system(.body, design: .monospaced))
            }

            Spacer()
        }
        .padding()
    }
}
