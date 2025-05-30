//
//  ContentView.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

import Foundation
import CoreBluetooth


import SwiftUI

struct BleButtonListenerView: View {
    @StateObject private var viewModel = BleButtonListenerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("📲 ESP32ボタン受信アプリ")
                .font(.title)

            VStack(alignment: .leading) {
                Text("❤️ 体力: \(viewModel.health)")
                ProgressView(value: Float(viewModel.health), total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
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
