//
//  NewVRApp.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/05/30.
//

import SwiftUI
import FirebaseCore

@main
struct NewVRApp: App {
    init() {
            FirebaseApp.configure()
            
            // オーディオマネージャーを初期化
            _ = LaserGameAudioManager.shared
        }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
