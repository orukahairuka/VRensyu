import SwiftUI
import Combine
import MapKit
import CoreLocation

// MARK: - レーザーゲーム用ヘルスバー
struct LaserHealthBar: View {
    let currentHealth: Int
    let maxHealth: Int
    @State private var animationProgress: Double = 0
    @State private var isLowHealth: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    
    private var healthPercentage: Double {
        Double(currentHealth) / Double(maxHealth)
    }
    
    private var healthColor: Color {
        switch healthPercentage {
        case 0.7...1.0:
            return LaserGameDesign.Colors.neonGreen
        case 0.3..<0.7:
            return LaserGameDesign.Colors.neonOrange
        default:
            return LaserGameDesign.Colors.neonRed
        }
    }
    
    var body: some View {
        HUDContainer(title: "HEALTH STATUS") {
            VStack(spacing: 8) {
                // デジタルHP表示
                HStack {
                    Text("HP")
                        .font(LaserGameDesign.Typography.caption)
                        .foregroundColor(LaserGameDesign.Colors.neonBlue)
                    
                    Spacer()
                    
                    Text("\(currentHealth)")
                        .font(LaserGameDesign.Typography.hud)
                        .foregroundColor(healthColor)
                        .neonGlow(color: healthColor, radius: 2)
                        .scaleEffect(pulseScale)
                    
                    Text("/ \(maxHealth)")
                        .font(LaserGameDesign.Typography.caption)
                        .foregroundColor(LaserGameDesign.Colors.neonBlue.opacity(0.7))
                }
                
                // レーザーヘルスバー
                ZStack(alignment: .leading) {
                    // ベース
                    Rectangle()
                        .fill(LaserGameDesign.Colors.darkAccent)
                        .frame(height: 20)
                        .laserBorder(color: LaserGameDesign.Colors.neonBlue.opacity(0.5), width: 1, cornerRadius: 4)
                    
                    // ヘルスバー本体
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        healthColor.opacity(0.8),
                                        healthColor,
                                        healthColor.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * animationProgress)
                            .overlay(
                                // スキャンライン効果
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 2)
                                    .offset(x: geometry.size.width * animationProgress - 1)
                            )
                            .neonGlow(color: healthColor, radius: 3)
                    }
                    .frame(height: 20)
                    .clipped()
                    
                    // 警告オーバーレイ
                    if isLowHealth {
                        Rectangle()
                            .fill(LaserGameDesign.Colors.danger.opacity(0.3))
                            .frame(height: 20)
                            .opacity(pulseScale > 1.0 ? 0.7 : 0.0)
                    }
                }
                .cornerRadius(4)
                
                // パーセンテージ表示
                HStack {
                    Text("\(Int(healthPercentage * 100))%")
                        .font(LaserGameDesign.Typography.caption)
                        .foregroundColor(healthColor)
                    
                    Spacer()
                    
                    if isLowHealth {
                        Text("⚠ CRITICAL")
                            .font(LaserGameDesign.Typography.caption)
                            .foregroundColor(LaserGameDesign.Colors.danger)
                            .neonGlow(color: LaserGameDesign.Colors.danger, radius: 1)
                    }
                }
            }
        }
        .onAppear {
            updateHealth()
        }
        .onChange(of: currentHealth) { _ in
            updateHealth()
        }
    }
    
    private func updateHealth() {
        withAnimation(.easeOut(duration: 0.5)) {
            animationProgress = healthPercentage
        }
        
        isLowHealth = healthPercentage < 0.3
        
        if isLowHealth {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        } else {
            pulseScale = 1.0
        }
    }
}

// MARK: - 戦術マップ
struct TacticalMapView: View {
    @ObservedObject var viewModel: MapLocationViewModelEnhanced
    @State private var radarSweepAngle: Double = 0
    @State private var scanLineOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // ベースマップ
            if let region = viewModel.region {
                Map(coordinateRegion: .constant(region), annotationItems: viewModel.userLocations) { location in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                        TacticalPlayerMarker(location: location)
                    }
                }
                .background(LaserGameDesign.Colors.darkBackground)
                .overlay(
                    // レーダーオーバーレイ
                    tacticalOverlay
                )
            } else {
                LoadingRadar()
            }
        }
        .laserBorder(color: LaserGameDesign.Colors.neonBlue, width: 2, cornerRadius: 0)
        .clipped()
    }
    
    @ViewBuilder
    private var tacticalOverlay: some View {
        ZStack {
            // レーダー範囲
            if viewModel.displayMode == .teammateWithRadar {
                Circle()
                    .stroke(
                        LaserGameDesign.Colors.neonGreen.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                    )
                    .frame(width: 200, height: 200)
                    .neonGlow(color: LaserGameDesign.Colors.neonGreen, radius: 2)
                
                // レーダースイープ
                RadarSweep(angle: radarSweepAngle)
                    .onAppear {
                        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                            radarSweepAngle = 360
                        }
                    }
            }
            
            // スキャンライン
            VStack {
                LaserGameDesign.ScanLine(color: LaserGameDesign.Colors.neonBlue)
                Spacer()
            }
            
            // HUD情報
            VStack {
                HStack {
                    TacticalHUD(viewModel: viewModel)
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - 戦術プレイヤーマーカー
struct TacticalPlayerMarker: View {
    let location: EnhancedLocationData
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    private var markerColor: Color {
        if location.isTeammate {
            return LaserGameDesign.Colors.teamBlue
        } else if location.isDelayed {
            return LaserGameDesign.Colors.neonOrange
        } else {
            return LaserGameDesign.Colors.teamRed
        }
    }
    
    var body: some View {
        ZStack {
            // 外側のリング
            Circle()
                .stroke(markerColor.opacity(0.3), lineWidth: 2)
                .frame(width: 40, height: 40)
                .scaleEffect(pulseScale)
            
            // メインマーカー
            Circle()
                .fill(markerColor)
                .frame(width: 20, height: 20)
                .neonGlow(color: markerColor, radius: 3)
            
            // ターゲットサイト
            if !location.isTeammate {
                Image(systemName: "scope")
                    .font(.system(size: 30, weight: .thin))
                    .foregroundColor(LaserGameDesign.Colors.neonRed)
                    .rotationEffect(.degrees(rotation))
            }
            
            // プレイヤー情報
            VStack(spacing: 2) {
                Spacer()
                
                Text(location.username.prefix(4))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .cornerRadius(2)
                
                Text("HP:\(location.hp)")
                    .font(.system(size: 6, weight: .medium, design: .monospaced))
                    .foregroundColor(markerColor)
                
                if location.isDelayed {
                    Text("⏱")
                        .font(.system(size: 8))
                }
            }
            .offset(y: 25)
        }
        .onAppear {
            // パルスアニメーション
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
            
            // 敵のターゲットサイト回転
            if !location.isTeammate {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

// MARK: - 戦術HUD
struct TacticalHUD: View {
    @ObservedObject var viewModel: MapLocationViewModelEnhanced
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 表示モード
            HStack {
                Text("MODE:")
                    .font(LaserGameDesign.Typography.caption)
                    .foregroundColor(LaserGameDesign.Colors.neonBlue)
                
                Text(viewModel.displayMode.description.uppercased())
                    .font(LaserGameDesign.Typography.caption)
                    .foregroundColor(LaserGameDesign.Colors.neonGreen)
                    .neonGlow(color: LaserGameDesign.Colors.neonGreen, radius: 1)
            }
            
            // 統計
            let teammates = viewModel.userLocations.filter { $0.isTeammate }
            let enemies = viewModel.userLocations.filter { !$0.isTeammate }
            
            HStack(spacing: 16) {
                // 味方
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALLIES")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(LaserGameDesign.Colors.teamBlue)
                    
                    Text("\(teammates.count)")
                        .font(LaserGameDesign.Typography.hud)
                        .foregroundColor(LaserGameDesign.Colors.teamBlue)
                        .neonGlow(color: LaserGameDesign.Colors.teamBlue, radius: 1)
                }
                
                // 敵
                if viewModel.displayMode != .teammateOnly {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HOSTILES")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(LaserGameDesign.Colors.teamRed)
                        
                        Text("\(enemies.count)")
                            .font(LaserGameDesign.Typography.hud)
                            .foregroundColor(LaserGameDesign.Colors.teamRed)
                            .neonGlow(color: LaserGameDesign.Colors.teamRed, radius: 1)
                    }
                }
            }
        }
        .padding(12)
        .background(LaserGameDesign.Colors.darkSecondary.opacity(0.8))
        .laserBorder(color: LaserGameDesign.Colors.neonBlue, width: 1, cornerRadius: 4)
    }
}

// MARK: - レーダースイープ
struct RadarSweep: View {
    let angle: Double
    
    var body: some View {
        ZStack {
            Path { path in
                let center = CGPoint(x: 100, y: 100)
                let radius: CGFloat = 100
                let startAngle = Angle.degrees(angle - 10)
                let endAngle = Angle.degrees(angle)
                
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.closeSubpath()
            }
            .fill(
                AngularGradient(
                    colors: [
                        LaserGameDesign.Colors.neonGreen.opacity(0.8),
                        LaserGameDesign.Colors.neonGreen.opacity(0.3),
                        Color.clear
                    ],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(10)
                )
            )
        }
        .frame(width: 200, height: 200)
        .rotationEffect(.degrees(angle))
    }
}

// MARK: - ローディングレーダー
struct LoadingRadar: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // レーダー画面
                Circle()
                    .stroke(LaserGameDesign.Colors.neonGreen, lineWidth: 2)
                    .frame(width: 200, height: 200)
                
                // 十字線
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 100))
                    path.addLine(to: CGPoint(x: 200, y: 100))
                    path.move(to: CGPoint(x: 100, y: 0))
                    path.addLine(to: CGPoint(x: 100, y: 200))
                }
                .stroke(LaserGameDesign.Colors.neonGreen.opacity(0.5), lineWidth: 1)
                .frame(width: 200, height: 200)
                
                // スイープライン
                Path { path in
                    path.move(to: CGPoint(x: 100, y: 100))
                    path.addLine(to: CGPoint(x: 100, y: 0))
                }
                .stroke(LaserGameDesign.Colors.neonGreen, lineWidth: 3)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(rotation))
                .neonGlow(color: LaserGameDesign.Colors.neonGreen, radius: 4)
            }
            
            Text("ACQUIRING SIGNAL...")
                .font(LaserGameDesign.Typography.body)
                .foregroundColor(LaserGameDesign.Colors.neonGreen)
                .neonGlow(color: LaserGameDesign.Colors.neonGreen, radius: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tacticalBackground()
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}