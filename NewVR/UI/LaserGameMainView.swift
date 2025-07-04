import SwiftUI
import AVFoundation
import MapKit
import CoreLocation

/// メインレーザーゲーム画面
struct LaserGameMainView: View {
    @StateObject private var viewModel = MapLocationViewModelEnhanced()
    @StateObject private var bleViewModel: BleViewModel
    @State private var showTeamSelection = false
    @State private var showSettings = false
    @State private var isGameActive = true
    @State private var lastDamageTime: Date?
    
    // アニメーション状態
    @State private var backgroundOffset: CGFloat = 0
    @State private var alertOpacity: Double = 0
    @State private var damageFlash: Bool = false
    
    init() {
        let container = ServiceContainer.shared
        let mapVM = MapLocationViewModelEnhanced()
        let bleVM = container.makeBleViewModel(healthManager: mapVM)
        
        self._bleViewModel = StateObject(wrappedValue: bleVM)
    }
    
    var body: some View {
        ZStack {
            // 動的背景
            tacticalBackground
            
            VStack(spacing: 0) {
                // トップHUD
                topHUD
                
                // メインコンテンツ
                mainContent
                
                // ボトムHUD
                bottomHUD
            }
            
            // ダメージエフェクト
            if damageFlash {
                Color.red.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // アラートオーバーレイ
            alertOverlay
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .damageReceived)) { _ in
            triggerDamageEffect()
        }
        .onAppear {
            startBackgroundAnimation()
        }
        .sheet(isPresented: $showTeamSelection) {
            LaserTeamSelectionView(isPresented: $showTeamSelection)
        }
        .sheet(isPresented: $showSettings) {
            LaserSettingsView(isPresented: $showSettings)
        }
    }
    
    // MARK: - Background
    private var tacticalBackground: some View {
        ZStack {
            LaserGameDesign.Colors.darkBackground
                .ignoresSafeArea()
            
            // 動的グリッド
            Path { path in
                let spacing: CGFloat = 25
                let offset = backgroundOffset.truncatingRemainder(dividingBy: spacing)
                
                for i in stride(from: -spacing + offset, through: UIScreen.main.bounds.width + spacing, by: spacing) {
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: i, y: UIScreen.main.bounds.height))
                }
                
                for i in stride(from: -spacing + offset, through: UIScreen.main.bounds.height + spacing, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: i))
                    path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: i))
                }
            }
            .stroke(LaserGameDesign.Colors.neonBlue.opacity(0.1), lineWidth: 0.5)
            
            // コーナーブラケット
            VStack {
                HStack {
                    cornerBracket(position: .topLeading)
                    Spacer()
                    cornerBracket(position: .topTrailing)
                }
                Spacer()
                HStack {
                    cornerBracket(position: .bottomLeading)
                    Spacer()
                    cornerBracket(position: .bottomTrailing)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Top HUD
    private var topHUD: some View {
        HStack {
            // ゲームタイトル
            VStack(alignment: .leading, spacing: 4) {
                Text("LASER TAG")
                    .font(LaserGameDesign.Typography.title)
                    .foregroundColor(LaserGameDesign.Colors.neonBlue)
                    .neonGlow(color: LaserGameDesign.Colors.neonBlue, radius: 4)
                
                Text("TACTICAL MODE")
                    .font(LaserGameDesign.Typography.caption)
                    .foregroundColor(LaserGameDesign.Colors.neonGreen)
            }
            
            Spacer()
            
            // ステータスインジケーター
            HStack(spacing: 16) {
                statusIndicator(
                    title: "BLE",
                    status: bleViewModel.isConnected ? "ONLINE" : "OFFLINE",
                    color: bleViewModel.isConnected ? LaserGameDesign.Colors.neonGreen : LaserGameDesign.Colors.neonRed
                )
                
                statusIndicator(
                    title: "GPS",
                    status: viewModel.region != nil ? "LOCKED" : "SEARCHING",
                    color: viewModel.region != nil ? LaserGameDesign.Colors.neonGreen : LaserGameDesign.Colors.neonOrange
                )
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(LaserGameDesign.Colors.neonBlue)
                }
                .buttonStyle(LaserButtonStyle(color: LaserGameDesign.Colors.neonBlue))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        HStack(spacing: 16) {
            // 左サイドパネル
            VStack(spacing: 16) {
                // ヘルスバー
                LaserHealthBar(
                    currentHealth: viewModel.health,
                    maxHealth: 300
                )
                
                // BLE接続状況
                connectionStatus
                
                // チームセレクター
                teamSelector
                
                Spacer()
            }
            .frame(width: 300)
            
            // メインマップ
            TacticalMapView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Bottom HUD
    private var bottomHUD: some View {
        HStack {
            // 表示モード切り替え
            HUDContainer(title: "DISPLAY MODE") {
                Picker("Mode", selection: $viewModel.displayMode) {
                    ForEach(MapDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.description.uppercased())
                            .tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorScheme(.dark)
            }
            
            Spacer()
            
            // アクションボタン
            HStack(spacing: 12) {
                Button("SCAN") {
                    triggerRadarScan()
                }
                .buttonStyle(LaserButtonStyle(color: LaserGameDesign.Colors.neonGreen))
                
                Button("RELOAD") {
                    reloadWeapon()
                }
                .buttonStyle(LaserButtonStyle(color: LaserGameDesign.Colors.neonOrange))
                
                Button(isGameActive ? "PAUSE" : "RESUME") {
                    isGameActive.toggle()
                }
                .buttonStyle(LaserButtonStyle(
                    color: isGameActive ? LaserGameDesign.Colors.neonRed : LaserGameDesign.Colors.neonGreen
                ))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Components
    private func statusIndicator(title: String, status: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(LaserGameDesign.Colors.neonBlue)
            
            Text(status)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
                .neonGlow(color: color, radius: 1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(LaserGameDesign.Colors.darkSecondary.opacity(0.7))
        .laserBorder(color: color, width: 1, cornerRadius: 4)
    }
    
    private var connectionStatus: some View {
        HUDContainer(title: "CONNECTION") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(bleViewModel.isConnected ? LaserGameDesign.Colors.neonGreen : LaserGameDesign.Colors.neonRed)
                        .frame(width: 8, height: 8)
                        .neonGlow(
                            color: bleViewModel.isConnected ? LaserGameDesign.Colors.neonGreen : LaserGameDesign.Colors.neonRed,
                            radius: 2
                        )
                    
                    Text(bleViewModel.connectionStatus)
                        .font(LaserGameDesign.Typography.caption)
                        .foregroundColor(LaserGameDesign.Colors.neonBlue)
                }
                
                if bleViewModel.discoveredDevicesCount > 0 {
                    Text("DEVICES: \(bleViewModel.discoveredDevicesCount)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(LaserGameDesign.Colors.neonGreen)
                }
            }
        }
    }
    
    private var teamSelector: some View {
        HUDContainer(title: "TEAM") {
            Button(action: { showTeamSelection = true }) {
                HStack {
                    Circle()
                        .fill(LaserGameDesign.Colors.teamBlue)
                        .frame(width: 16, height: 16)
                    
                    Text("BLUE TEAM")
                        .font(LaserGameDesign.Typography.caption)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(LaserGameDesign.Colors.neonBlue)
            }
            .buttonStyle(LaserButtonStyle(color: LaserGameDesign.Colors.teamBlue))
        }
    }
    
    private var alertOverlay: some View {
        VStack {
            if viewModel.health <= 50 {
                Text("⚠ CRITICAL HEALTH ⚠")
                    .font(LaserGameDesign.Typography.subtitle)
                    .foregroundColor(LaserGameDesign.Colors.danger)
                    .neonGlow(color: LaserGameDesign.Colors.danger, radius: 6)
                    .opacity(alertOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            alertOpacity = 1.0
                        }
                    }
            }
            Spacer()
        }
        .padding(.top, 100)
    }
    
    private func cornerBracket(position: CornerPosition) -> some View {
        ZStack {
            Path { path in
                let size: CGFloat = 30
                switch position {
                case .topLeading:
                    path.move(to: CGPoint(x: 0, y: size))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: size, y: 0))
                case .topTrailing:
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: size, y: 0))
                    path.addLine(to: CGPoint(x: size, y: size))
                case .bottomLeading:
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: size))
                    path.addLine(to: CGPoint(x: size, y: size))
                case .bottomTrailing:
                    path.move(to: CGPoint(x: 0, y: size))
                    path.addLine(to: CGPoint(x: size, y: size))
                    path.addLine(to: CGPoint(x: size, y: 0))
                }
            }
            .stroke(LaserGameDesign.Colors.neonBlue, lineWidth: 2)
            .neonGlow(color: LaserGameDesign.Colors.neonBlue, radius: 2)
        }
        .frame(width: 30, height: 30)
    }
    
    // MARK: - Actions
    private func startBackgroundAnimation() {
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            backgroundOffset = 100
        }
    }
    
    private func triggerDamageEffect() {
        withAnimation(.easeInOut(duration: 0.1)) {
            damageFlash = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                damageFlash = false
            }
        }
        
        // 触覚フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    private func triggerRadarScan() {
        // レーダースキャンアニメーション
        print("🎯 Radar scan initiated")
    }
    
    private func reloadWeapon() {
        // 武器リロードアニメーション
        print("🔫 Weapon reloaded")
    }
}

enum CornerPosition {
    case topLeading, topTrailing, bottomLeading, bottomTrailing
}

// MARK: - Notification Extension
extension Notification.Name {
    static let damageReceived = Notification.Name("damageReceived")
}

// MARK: - Preview
#Preview {
    LaserGameMainView()
        .preferredColorScheme(.dark)
}