//
//  ContentView.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

import SwiftUI
import CoreBluetooth

struct BleButtonListenerView: View {
    @StateObject private var viewModel = BleButtonListenerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("📲 ESP32ボタン受信アプリ")
                .font(.title)

            VStack(alignment: .leading, spacing: 10) {
                Text("❤️ 体力: \(viewModel.health)")
                ProgressView(value: Float(viewModel.health), total: 100)
                    .progressViewStyle(LinearProgressViewStyle())

                // 🔽 ゲームオーバーと復活ボタン
                if viewModel.health == 0 {
                    Text("💀 ゲームオーバー")
                        .font(.title)
                        .foregroundColor(.red)
                        .bold()

                    Button(action: {
                        viewModel.health = 100
                        viewModel.log.append("\n🔁 体力を復活しました")
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

            ScrollView {
                Text(viewModel.log)
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
