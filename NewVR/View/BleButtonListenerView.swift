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
        VStack(alignment: .leading) {
            Text("📲 ESP32ボタン受信アプリ")
                .font(.title)
                .padding(.bottom, 10)

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
