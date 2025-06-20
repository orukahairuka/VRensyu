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
    @State private var showUsernameSheet = false
    @State private var username: String = UserDefaults.standard.string(forKey: "username") ?? ""
    @State private var groupCode: String = UserDefaults.standard.string(forKey: "groupCode") ?? ""

    var targetESPName: String {
        if username.hasSuffix("1") {
            return "ESP32 IR Button 1"
        } else if username.hasSuffix("2") {
            return "ESP32 IR Button 2"
        } else {
            return "未設定"
        }
    }
    init() {
        let mapVM = MapLocationViewModel()
        _mapViewModel = StateObject(wrappedValue: mapVM)
        _bleViewModel = StateObject(wrappedValue: BleButtonListenerViewModel(mapViewModel: mapVM))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("📲 ESP32ボタン受信アプリ")
                .font(.title)
            Text("🛰️ 接続予定デバイス: \(targetESPName)")
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 10) {
                Text("❤️ 体力: \(mapViewModel.health)")
                ProgressView(value: Float(mapViewModel.health), total: 300)
                    .progressViewStyle(LinearProgressViewStyle())

                if mapViewModel.health == 0 {
                    Text("💀 ゲームオーバー")
                        .font(.title)
                        .foregroundColor(.red)
                        .bold()

                    Button(action: {
                        mapViewModel.updateHealth(300)
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
        .onAppear {
            if username.isEmpty || groupCode.isEmpty {
                showUsernameSheet = true
            }
        }

        .sheet(isPresented: $showUsernameSheet) {
            UsernameInputView(username: $username, groupCode: $groupCode)
        }

    }
}
