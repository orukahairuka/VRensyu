import SwiftUI
import AVFoundation

/// 超おしゃれなメインゲーム画面
struct ModernGameView: View {
    @StateObject private var viewModel = MapLocationViewModelEnhanced()
    @StateObject private var bleViewModel: BleViewModel
    @State private var showTeamSelection = false
    @State private var showSettings = false
    @State private var backgroundOffset: CGFloat = 0
    @State private var isGameActive = true
    @State private var damageFlash = false
    @State private var selectedTab: GameTab = .map
    
    enum GameTab: CaseIterable {
        case map, stats, settings
        
        var icon: String {
            switch self {
            case .map: return "map.fill"
            case .stats: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var title: String {
            switch self {
            case .map: return "Tactical"
            case .stats: return "Analytics"
            case .settings: return "Settings"
            }
        }
    }
    
    init() {
        let container = ServiceContainer.shared
        let mapVM = MapLocationViewModelEnhanced()
        let bleVM = container.makeBleViewModel(healthManager: mapVM)
        
        self._bleViewModel = StateObject(wrappedValue: bleVM)
    }
    
    var body: some View {
        ZStack {
            // 動的背景
            dynamicBackground
            
            VStack(spacing: 0) {
                // トップナビゲーション
                topNavigation
                
                // メインコンテンツ
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // ボトムタブナビゲーション
                bottomTabNavigation
            }
            
            // ダメージエフェクト
            if damageFlash {
                ModernDesign.Colors.error.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: damageFlash)
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .damageReceived)) { _ in
            triggerDamageEffect()
        }
        .onAppear {
            startBackgroundAnimation()
        }
        .sheet(isPresented: $showTeamSelection) {
            ModernTeamSelectionView(isPresented: $showTeamSelection)
        }
        .sheet(isPresented: $showSettings) {
            ModernSettingsView(isPresented: $showSettings)
        }
    }
    
    // MARK: - Background
    private var dynamicBackground: some View {
        ZStack {
            ModernDesign.Colors.backgroundGradient
                .ignoresSafeArea()
            
            ParticleEffect(particleCount: 20)
                .opacity(0.4)
                .ignoresSafeArea()
            
            // 動的グリッド
            GeometryReader { geometry in
                Path { path in
                    let spacing: CGFloat = 60
                    let offset = backgroundOffset.truncatingRemainder(dividingBy: spacing)
                    
                    for i in stride(from: -spacing + offset, through: geometry.size.width + spacing, by: spacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i, y: geometry.size.height))
                    }
                    
                    for i in stride(from: -spacing + offset, through: geometry.size.height + spacing, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: i))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: i))
                    }
                }
                .stroke(ModernDesign.Colors.primary.opacity(0.05), lineWidth: 1)
            }
        }
    }
    
    // MARK: - Top Navigation
    private var topNavigation: some View {
        HStack {
            // ゲームタイトル
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXUS")
                    .font(ModernDesign.Typography.displayMedium)
                    .fontWeight(.thin)
                    .foregroundStyle(ModernDesign.Colors.holographicGradient)
                    .tracking(3)
                
                Text("Tactical Gaming Suite")
                    .font(ModernDesign.Typography.labelMedium)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .tracking(1.5)
                    .textCase(.uppercase)
            }
            
            Spacer()
            
            // クイックアクション
            HStack(spacing: ModernDesign.Spacing.md) {
                // 通知ボタン
                Button(action: {}) {
                    ZStack {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        
                        // 通知バッジ
                        Circle()
                            .fill(ModernDesign.Colors.error)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }
                .buttonStyle(ModernButtonStyle(variant: .ghost, size: .medium))
                
                // プロフィールボタン
                Button(action: { showTeamSelection = true }) {
                    Circle()
                        .fill(ModernDesign.Colors.primaryGradient)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("A")
                                .font(ModernDesign.Typography.labelMedium)
                                .foregroundColor(.white)
                        )
                }
                .glassmorphism()
            }
        }
        .padding(.horizontal, ModernDesign.Spacing.lg)
        .padding(.top, ModernDesign.Spacing.md)
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: ModernDesign.Spacing.lg) {
                switch selectedTab {
                case .map:
                    mapContent
                case .stats:
                    statsContent
                case .settings:
                    settingsContent
                }
            }
            .padding(.horizontal, ModernDesign.Spacing.lg)
            .padding(.vertical, ModernDesign.Spacing.md)
        }
    }
    
    private var mapContent: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            // ヘルスバー
            ModernHealthBar(
                currentHealth: viewModel.health,
                maxHealth: 300
            )
            .floating(duration: 4.0, offset: 5)
            
            // 接続ステータス
            ModernConnectionStatus(bleViewModel: bleViewModel)
                .floating(duration: 3.5, offset: 8)
            
            // メインマップ
            ModernMapView(viewModel: viewModel)
                .frame(height: 400)
                .floating(duration: 5.0, offset: 3)
            
            // クイックアクション
            quickActions
        }
    }
    
    private var statsContent: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            // 統計カード
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ModernDesign.Spacing.md) {
                statCard(title: "Matches", value: "24", trend: "+3")
                statCard(title: "Wins", value: "18", trend: "+2")
                statCard(title: "Accuracy", value: "87%", trend: "+5%")
                statCard(title: "Rank", value: "#12", trend: "↑4")
            }
            
            // パフォーマンスチャート
            performanceChart
            
            // 最近のマッチ
            recentMatches
        }
    }
    
    private var settingsContent: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            // 設定セクション
            settingsSection(title: "GAME", items: [
                ("Sound Effects", "speaker.wave.3.fill", true),
                ("Haptic Feedback", "iphone.radiowaves.left.and.right", true),
                ("Auto-reconnect", "arrow.clockwise", false)
            ])
            
            settingsSection(title: "DISPLAY", items: [
                ("Dark Mode", "moon.fill", true),
                ("Animations", "sparkles", true),
                ("Particle Effects", "snow", true)
            ])
            
            settingsSection(title: "PRIVACY", items: [
                ("Location Services", "location.fill", true),
                ("Analytics", "chart.bar.fill", false),
                ("Crash Reports", "exclamationmark.triangle.fill", true)
            ])
        }
    }
    
    private var quickActions: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            // スキャンボタン
            Button(action: {}) {
                HStack {
                    Image(systemName: "radar")
                        .font(.title2)
                    Text("SCAN")
                        .font(ModernDesign.Typography.labelLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
            }
            .buttonStyle(ModernButtonStyle(variant: .primary, size: .large))
            .frame(maxWidth: .infinity)
            
            // リロードボタン
            Button(action: {}) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                    Text("RELOAD")
                        .font(ModernDesign.Typography.labelLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
            }
            .buttonStyle(ModernButtonStyle(variant: .accent, size: .large))
            .frame(maxWidth: .infinity)
        }
    }
    
    private func statCard(title: String, value: String, trend: String) -> some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
            HStack {
                Text(title)
                    .font(ModernDesign.Typography.labelMedium)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Spacer()
                
                Text(trend)
                    .font(ModernDesign.Typography.labelSmall)
                    .foregroundColor(ModernDesign.Colors.success)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ModernDesign.Colors.success.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Text(value)
                .font(ModernDesign.Typography.displaySmall)
                .fontWeight(.thin)
                .foregroundStyle(ModernDesign.Colors.primaryGradient)
        }
        .padding(ModernDesign.Spacing.lg)
        .glassmorphism()
        .modernBorder()
    }
    
    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
            Text("PERFORMANCE")
                .font(ModernDesign.Typography.labelMedium)
                .foregroundColor(ModernDesign.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
            
            // シンプルなチャート
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { index in
                    Rectangle()
                        .fill(ModernDesign.Colors.primaryGradient)
                        .frame(width: 24, height: CGFloat.random(in: 20...100))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(height: 120)
        }
        .padding(ModernDesign.Spacing.lg)
        .glassmorphism()
        .modernBorder()
    }
    
    private var recentMatches: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
            Text("RECENT MATCHES")
                .font(ModernDesign.Typography.labelMedium)
                .foregroundColor(ModernDesign.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
            
            VStack(spacing: ModernDesign.Spacing.sm) {
                ForEach(0..<3) { index in
                    matchRow(
                        result: index == 0 ? "VICTORY" : "DEFEAT",
                        map: "Arena \(index + 1)",
                        score: "\(Int.random(in: 15...25))-\(Int.random(in: 8...20))"
                    )
                }
            }
        }
        .padding(ModernDesign.Spacing.lg)
        .glassmorphism()
        .modernBorder()
    }
    
    private func matchRow(result: String, map: String, score: String) -> some View {
        HStack {
            Circle()
                .fill(result == "VICTORY" ? ModernDesign.Colors.success : ModernDesign.Colors.error)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result)
                    .font(ModernDesign.Typography.labelMedium)
                    .foregroundColor(result == "VICTORY" ? ModernDesign.Colors.success : ModernDesign.Colors.error)
                
                Text(map)
                    .font(ModernDesign.Typography.bodySmall)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(score)
                .font(ModernDesign.Typography.labelMedium)
                .foregroundColor(ModernDesign.Colors.textPrimary)
        }
        .padding(.vertical, ModernDesign.Spacing.sm)
    }
    
    private func settingsSection(title: String, items: [(String, String, Bool)]) -> some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
            Text(title)
                .font(ModernDesign.Typography.labelMedium)
                .foregroundColor(ModernDesign.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
            
            VStack(spacing: ModernDesign.Spacing.sm) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    settingsRow(title: item.0, icon: item.1, isEnabled: item.2)
                }
            }
        }
        .padding(ModernDesign.Spacing.lg)
        .glassmorphism()
        .modernBorder()
    }
    
    private func settingsRow(title: String, icon: String, isEnabled: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ModernDesign.Colors.primary)
                .frame(width: 24)
            
            Text(title)
                .font(ModernDesign.Typography.bodyMedium)
                .foregroundColor(ModernDesign.Colors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .labelsHidden()
                .scaleEffect(0.8)
        }
        .padding(.vertical, ModernDesign.Spacing.sm)
    }
    
    // MARK: - Bottom Tab Navigation
    private var bottomTabNavigation: some View {
        HStack {
            ForEach(GameTab.allCases, id: \.self) { tab in
                Button(action: { 
                    withAnimation(.spring()) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title2)
                            .foregroundColor(selectedTab == tab ? ModernDesign.Colors.primary : ModernDesign.Colors.textSecondary)
                        
                        Text(tab.title)
                            .font(ModernDesign.Typography.labelSmall)
                            .foregroundColor(selectedTab == tab ? ModernDesign.Colors.primary : ModernDesign.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernDesign.Spacing.sm)
                    .background(
                        selectedTab == tab ? ModernDesign.Colors.primary.opacity(0.1) : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.medium))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, ModernDesign.Spacing.lg)
        .padding(.vertical, ModernDesign.Spacing.md)
        .glassmorphism()
        .modernBorder()
    }
    
    // MARK: - Actions
    private func startBackgroundAnimation() {
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            backgroundOffset = 200
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
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Preview
#Preview {
    ModernGameView()
        .preferredColorScheme(.dark)
}