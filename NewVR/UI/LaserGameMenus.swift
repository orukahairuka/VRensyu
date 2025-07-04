import SwiftUI
import UIKit

// MARK: - レーザーゲーム風チーム選択
struct LaserTeamSelectionView: View {
    @Binding var isPresented: Bool
    @State private var selectedTeam: TeamManager.Team?
    @State private var glowIntensity: Double = 0.5
    @State private var scanlineOffset: CGFloat = -300
    
    private let teams = [
        (name: "ALPHA", color: LaserGameDesign.Colors.teamRed, code: "RED"),
        (name: "BRAVO", color: LaserGameDesign.Colors.teamBlue, code: "BLUE"),
        (name: "CHARLIE", color: LaserGameDesign.Colors.teamGreen, code: "GREEN"),
        (name: "DELTA", color: LaserGameDesign.Colors.teamYellow, code: "YELLOW"),
        (name: "ECHO", color: LaserGameDesign.Colors.teamOrange, code: "ORANGE")
    ]
    
    var body: some View {
        ZStack {
            // 背景
            LaserGameDesign.Colors.darkBackground
                .ignoresSafeArea()
            
            // グリッドパターン
            tacticalGridBackground
            
            VStack(spacing: 30) {
                // ヘッダー
                header
                
                // チーム選択グリッド
                teamGrid
                
                Spacer()
                
                // アクションボタン
                actionButtons
            }
            .padding()
            
            // スキャンライン効果
            scanlineOverlay
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            Text("SELECT SQUAD")
                .font(LaserGameDesign.Typography.title)
                .foregroundColor(LaserGameDesign.Colors.neonBlue)
                .neonGlow(color: LaserGameDesign.Colors.neonBlue, radius: 6)
            
            Text("Choose your tactical unit for the mission")
                .font(LaserGameDesign.Typography.caption)
                .foregroundColor(LaserGameDesign.Colors.neonBlue.opacity(0.8))
                .textCase(.uppercase)
        }
        .padding(.top, 20)
    }
    
    private var teamGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 20) {
            ForEach(teams.indices, id: \.self) { index in
                let team = teams[index]
                LaserTeamCard(
                    name: team.name,
                    color: team.color,
                    code: team.code,
                    isSelected: selectedTeam?.code == team.code,
                    onSelect: {
                        selectedTeam = TeamManager.Team(
                            code: team.code,
                            name: team.name,
                            color: colorToTeamColor(team.color)
                        )
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button("DEPLOY TO BATTLEFIELD") {
                deployToGame()
            }
            .buttonStyle(LaserButtonStyle(
                color: LaserGameDesign.Colors.neonGreen,
                isActive: selectedTeam != nil
            ))
            .disabled(selectedTeam == nil)
            
            Button("ABORT MISSION") {
                isPresented = false
            }
            .buttonStyle(LaserButtonStyle(
                color: LaserGameDesign.Colors.neonRed
            ))
        }
        .padding(.bottom, 30)
    }
    
    private var tacticalGridBackground: some View {
        Path { path in
            let spacing: CGFloat = 40
            let bounds = UIScreen.main.bounds
            
            for i in stride(from: 0, through: bounds.width, by: spacing) {
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i, y: bounds.height))
            }
            
            for i in stride(from: 0, through: bounds.height, by: spacing) {
                path.move(to: CGPoint(x: 0, y: i))
                path.addLine(to: CGPoint(x: bounds.width, y: i))
            }
        }
        .stroke(LaserGameDesign.Colors.neonBlue.opacity(0.1), lineWidth: 1)
    }
    
    private var scanlineOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        LaserGameDesign.Colors.neonBlue.opacity(0.6),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 3)
            .offset(y: scanlineOffset)
            .allowsHitTesting(false)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
        
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            scanlineOffset = 300
        }
    }
    
    private func deployToGame() {
        // チーム選択を保存
        if let team = selectedTeam {
            UserDefaults.standard.set(team.code, forKey: "groupCode")
            UserDefaults.standard.set(team.name, forKey: "teamName")
        }
        isPresented = false
    }
    
    private func colorToTeamColor(_ color: Color) -> TeamManager.Team.TeamColor {
        switch color {
        case LaserGameDesign.Colors.teamRed: return .red
        case LaserGameDesign.Colors.teamBlue: return .blue
        case LaserGameDesign.Colors.teamGreen: return .green
        case LaserGameDesign.Colors.teamYellow: return .yellow
        case LaserGameDesign.Colors.teamOrange: return .orange
        default: return .blue
        }
    }
}

// MARK: - レーザーチームカード
struct LaserTeamCard: View {
    let name: String
    let color: Color
    let code: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var borderIntensity: Double = 0.3
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                // チームエンブレム
                ZStack {
                    Circle()
                        .stroke(color, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .neonGlow(color: color, radius: isSelected ? 8 : 4)
                    
                    Image(systemName: "shield.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(color)
                        .scaleEffect(pulseScale)
                }
                
                // チーム情報
                VStack(spacing: 4) {
                    Text("SQUAD \(name)")
                        .font(LaserGameDesign.Typography.body)
                        .foregroundColor(color)
                        .fontWeight(.black)
                    
                    Text("TACTICAL UNIT")
                        .font(LaserGameDesign.Typography.caption)
                        .foregroundColor(LaserGameDesign.Colors.neonBlue.opacity(0.7))
                    
                    // ステータス
                    HStack {
                        Circle()
                            .fill(LaserGameDesign.Colors.neonGreen)
                            .frame(width: 6, height: 6)
                        
                        Text("OPERATIONAL")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(LaserGameDesign.Colors.neonGreen)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    LaserGameDesign.Colors.darkSecondary.opacity(0.8)
                    
                    if isSelected {
                        color.opacity(0.1)
                    }
                }
            )
            .laserBorder(
                color: isSelected ? color : color.opacity(0.5),
                width: isSelected ? 3 : 1,
                cornerRadius: 12
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
            borderIntensity = 0.8
        }
    }
}

// MARK: - レーザーゲーム設定画面
struct LaserSettingsView: View {
    @Binding var isPresented: Bool
    @State private var radarRange: Double = 100
    @State private var soundEnabled: Bool = true
    @State private var vibrationEnabled: Bool = true
    @State private var displayMode: MapDisplayMode = .teammateOnly
    
    var body: some View {
        NavigationView {
            ZStack {
                LaserGameDesign.Colors.darkBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 戦術設定
                        tacticalSettings
                        
                        // オーディオ設定
                        audioSettings
                        
                        // システム設定
                        systemSettings
                        
                        // デバッグ情報
                        debugInfo
                    }
                    .padding()
                }
            }
            .navigationTitle("TACTICAL CONFIG")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("SAVE") {
                        saveSettings()
                        isPresented = false
                    }
                    .buttonStyle(LaserButtonStyle(color: LaserGameDesign.Colors.neonGreen))
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CANCEL") {
                        isPresented = false
                    }
                    .buttonStyle(LaserButtonStyle(color: LaserGameDesign.Colors.neonRed))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var tacticalSettings: some View {
        HUDContainer(title: "TACTICAL PARAMETERS") {
            VStack(spacing: 16) {
                // レーダー範囲
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("RADAR RANGE")
                            .font(LaserGameDesign.Typography.caption)
                            .foregroundColor(LaserGameDesign.Colors.neonBlue)
                        
                        Spacer()
                        
                        Text("\(Int(radarRange))M")
                            .font(LaserGameDesign.Typography.caption)
                            .foregroundColor(LaserGameDesign.Colors.neonGreen)
                    }
                    
                    Slider(value: $radarRange, in: 50...500, step: 10)
                        .accentColor(LaserGameDesign.Colors.neonBlue)
                }
                
                // 表示モード
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEFAULT DISPLAY MODE")
                        .font(LaserGameDesign.Typography.caption)
                        .foregroundColor(LaserGameDesign.Colors.neonBlue)
                    
                    Picker("Mode", selection: $displayMode) {
                        ForEach(MapDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.description.uppercased()).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
    
    private var audioSettings: some View {
        HUDContainer(title: "AUDIO SYSTEMS") {
            VStack(spacing: 16) {
                Toggle("SOUND EFFECTS", isOn: $soundEnabled)
                    .font(LaserGameDesign.Typography.caption)
                    .foregroundColor(LaserGameDesign.Colors.neonBlue)
                
                Toggle("HAPTIC FEEDBACK", isOn: $vibrationEnabled)
                    .font(LaserGameDesign.Typography.caption)
                    .foregroundColor(LaserGameDesign.Colors.neonBlue)
            }
        }
    }
    
    private var systemSettings: some View {
        HUDContainer(title: "SYSTEM STATUS") {
            VStack(alignment: .leading, spacing: 12) {
                systemStatusRow("GPS", "OPERATIONAL", LaserGameDesign.Colors.neonGreen)
                systemStatusRow("BLUETOOTH", "SCANNING", LaserGameDesign.Colors.neonOrange)
                systemStatusRow("FIREBASE", "CONNECTED", LaserGameDesign.Colors.neonGreen)
                systemStatusRow("SENSORS", "CALIBRATED", LaserGameDesign.Colors.neonGreen)
            }
        }
    }
    
    private var debugInfo: some View {
        HUDContainer(title: "DEBUG INFO") {
            VStack(alignment: .leading, spacing: 8) {
                debugRow("BUILD", "v1.0.0")
                debugRow("DEVICE", UIDevice.current.model)
                debugRow("OS", "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                debugRow("MEMORY", "Available")
            }
        }
    }
    
    private func systemStatusRow(_ system: String, _ status: String, _ color: Color) -> some View {
        HStack {
            Text(system)
                .font(LaserGameDesign.Typography.caption)
                .foregroundColor(LaserGameDesign.Colors.neonBlue)
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .neonGlow(color: color, radius: 1)
                
                Text(status)
                    .font(LaserGameDesign.Typography.caption)
                    .foregroundColor(color)
            }
        }
    }
    
    private func debugRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(LaserGameDesign.Typography.caption)
                .foregroundColor(LaserGameDesign.Colors.neonBlue.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(LaserGameDesign.Typography.caption)
                .foregroundColor(LaserGameDesign.Colors.neonGreen.opacity(0.7))
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(radarRange, forKey: "radarRange")
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(vibrationEnabled, forKey: "vibrationEnabled")
        // 他の設定も保存
    }
}

#Preview {
    LaserTeamSelectionView(isPresented: .constant(true))
}