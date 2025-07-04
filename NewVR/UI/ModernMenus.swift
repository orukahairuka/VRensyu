import SwiftUI
import UIKit

// MARK: - 超おしゃれなチーム選択
struct ModernTeamSelectionView: View {
    @Binding var isPresented: Bool
    @State private var selectedTeam: String?
    @State private var animationPhase: Double = 0
    @State private var floatingOffset: CGFloat = 0
    
    private let teams = [
        (name: "NEXUS", color: ModernDesign.Colors.primary, gradient: ModernDesign.Colors.primaryGradient),
        (name: "QUANTUM", color: ModernDesign.Colors.accent, gradient: ModernDesign.Colors.accentGradient),
        (name: "INFINITY", color: ModernDesign.Colors.success, gradient: LinearGradient(colors: [ModernDesign.Colors.success, Color(red: 0.4, green: 1.0, blue: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)),
        (name: "PHANTOM", color: ModernDesign.Colors.warning, gradient: LinearGradient(colors: [ModernDesign.Colors.warning, Color(red: 1.0, green: 0.8, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)),
        (name: "VORTEX", color: ModernDesign.Colors.error, gradient: LinearGradient(colors: [ModernDesign.Colors.error, Color(red: 1.0, green: 0.5, blue: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
    ]
    
    var body: some View {
        ZStack {
            // 背景
            ModernDesign.Colors.backgroundGradient
                .ignoresSafeArea()
            
            ParticleEffect(particleCount: 40)
                .opacity(0.6)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.xl) {
                    // ヘッダー
                    header
                    
                    // チーム選択グリッド
                    teamGrid
                    
                    // アクションボタン
                    actionButtons
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var header: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            // タイトル
            VStack(spacing: ModernDesign.Spacing.sm) {
                Text("SELECT TEAM")
                    .font(ModernDesign.Typography.displayLarge)
                    .fontWeight(.thin)
                    .foregroundStyle(ModernDesign.Colors.holographicGradient)
                    .tracking(4)
                    .offset(y: floatingOffset)
                
                Text("Choose your squad for the ultimate tactical experience")
                    .font(ModernDesign.Typography.bodyMedium)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .tracking(1)
            }
            
            // 装飾的要素
            HStack(spacing: ModernDesign.Spacing.sm) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(ModernDesign.Colors.primaryGradient)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase > Double(index) * 0.3 ? 1.5 : 1.0)
                        .opacity(animationPhase > Double(index) * 0.3 ? 1.0 : 0.5)
                }
            }
        }
        .padding(.top, ModernDesign.Spacing.xxl)
    }
    
    private var teamGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: ModernDesign.Spacing.md),
            GridItem(.flexible(), spacing: ModernDesign.Spacing.md)
        ], spacing: ModernDesign.Spacing.lg) {
            ForEach(teams.indices, id: \.self) { index in
                let team = teams[index]
                ModernTeamCard(
                    name: team.name,
                    gradient: team.gradient,
                    baseColor: team.color,
                    isSelected: selectedTeam == team.name,
                    animationDelay: Double(index) * 0.1
                ) {
                    withAnimation(.spring()) {
                        selectedTeam = team.name
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            Button("DEPLOY TO BATTLEFIELD") {
                deployToGame()
            }
            .buttonStyle(ModernButtonStyle(variant: .primary, size: .large))
            .disabled(selectedTeam == nil)
            .opacity(selectedTeam != nil ? 1.0 : 0.5)
            .frame(maxWidth: .infinity)
            
            Button("CANCEL") {
                isPresented = false
            }
            .buttonStyle(ModernButtonStyle(variant: .ghost, size: .medium))
            .frame(maxWidth: .infinity)
        }
        .padding(.top, ModernDesign.Spacing.xl)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            floatingOffset = 10
        }
        
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
    
    private func deployToGame() {
        if let team = selectedTeam {
            UserDefaults.standard.set(team, forKey: "selectedTeam")
        }
        isPresented = false
    }
}

// MARK: - 超おしゃれなチームカード
struct ModernTeamCard: View {
    let name: String
    let gradient: LinearGradient
    let baseColor: Color
    let isSelected: Bool
    let animationDelay: Double
    let onSelect: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = 0
    @State private var glowIntensity: Double = 0.3
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: ModernDesign.Spacing.lg) {
                // チームエンブレム
                ZStack {
                    // 外側のリング
                    Circle()
                        .stroke(gradient, lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(rotation))
                    
                    // 内側のグロー
                    Circle()
                        .fill(gradient)
                        .frame(width: 60, height: 60)
                        .blur(radius: glowIntensity * 10)
                        .opacity(glowIntensity)
                    
                    // 中央のアイコン
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(gradient)
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                }
                
                // チーム名
                VStack(spacing: ModernDesign.Spacing.xs) {
                    Text(name)
                        .font(ModernDesign.Typography.headlineSmall)
                        .fontWeight(.medium)
                        .foregroundStyle(gradient)
                        .tracking(2)
                    
                    Text("TACTICAL UNIT")
                        .font(ModernDesign.Typography.labelSmall)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
                
                // ステータス
                HStack(spacing: ModernDesign.Spacing.xs) {
                    Circle()
                        .fill(ModernDesign.Colors.success)
                        .frame(width: 6, height: 6)
                    
                    Text("ACTIVE")
                        .font(ModernDesign.Typography.labelSmall)
                        .foregroundColor(ModernDesign.Colors.success)
                        .tracking(1)
                }
            }
            .padding(ModernDesign.Spacing.xl)
            .frame(maxWidth: .infinity)
            .aspectRatio(0.8, contentMode: .fit)
            .glassmorphism(opacity: isSelected ? 0.4 : 0.2)
            .modernBorder(gradient: isSelected ? gradient : LinearGradient(colors: [ModernDesign.Colors.surface], startPoint: .top, endPoint: .bottom))
            .scaleEffect(scale)
            .modernShadow(isSelected ? (color: baseColor.opacity(0.4), radius: 20, x: 0, y: 0) : ModernDesign.Shadow.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring().delay(animationDelay)) {
                scale = 1.0
            }
            
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
        }
    }
}

// MARK: - 超おしゃれな設定画面
struct ModernSettingsView: View {
    @Binding var isPresented: Bool
    @State private var soundEnabled = true
    @State private var hapticEnabled = true
    @State private var animationsEnabled = true
    @State private var particlesEnabled = true
    @State private var radarRange: Double = 100
    
    var body: some View {
        NavigationView {
            ZStack {
                ModernDesign.Colors.backgroundGradient
                    .ignoresSafeArea()
                
                ParticleEffect(particleCount: 20)
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: ModernDesign.Spacing.xl) {
                        // 音響設定
                        audioSettings
                        
                        // 表示設定
                        displaySettings
                        
                        // ゲーム設定
                        gameSettings
                        
                        // システム情報
                        systemInfo
                        
                        // アバウト
                        aboutSection
                    }
                    .padding(ModernDesign.Spacing.lg)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .buttonStyle(ModernButtonStyle(variant: .primary, size: .medium))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var audioSettings: some View {
        ModernSettingsSection(title: "AUDIO & HAPTICS") {
            VStack(spacing: ModernDesign.Spacing.md) {
                ModernToggleRow(
                    title: "Sound Effects",
                    subtitle: "Game audio and notifications",
                    icon: "speaker.wave.3.fill",
                    isOn: $soundEnabled
                )
                
                ModernToggleRow(
                    title: "Haptic Feedback",
                    subtitle: "Tactile responses for actions",
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: $hapticEnabled
                )
            }
        }
    }
    
    private var displaySettings: some View {
        ModernSettingsSection(title: "DISPLAY & EFFECTS") {
            VStack(spacing: ModernDesign.Spacing.md) {
                ModernToggleRow(
                    title: "Smooth Animations",
                    subtitle: "Enhanced visual transitions",
                    icon: "sparkles",
                    isOn: $animationsEnabled
                )
                
                ModernToggleRow(
                    title: "Particle Effects",
                    subtitle: "Background particle system",
                    icon: "snow",
                    isOn: $particlesEnabled
                )
            }
        }
    }
    
    private var gameSettings: some View {
        ModernSettingsSection(title: "GAME SETTINGS") {
            VStack(spacing: ModernDesign.Spacing.md) {
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                    HStack {
                        Image(systemName: "radar")
                            .font(.title3)
                            .foregroundStyle(ModernDesign.Colors.primaryGradient)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Radar Range")
                                .font(ModernDesign.Typography.bodyMedium)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            
                            Text("Detection radius in meters")
                                .font(ModernDesign.Typography.bodySmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(radarRange))m")
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundStyle(ModernDesign.Colors.accentGradient)
                    }
                    
                    Slider(value: $radarRange, in: 50...500, step: 10)
                        .accentColor(ModernDesign.Colors.accent)
                }
                .padding(ModernDesign.Spacing.md)
                .glassmorphism(opacity: 0.1)
            }
        }
    }
    
    private var systemInfo: some View {
        ModernSettingsSection(title: "SYSTEM") {
            VStack(spacing: ModernDesign.Spacing.sm) {
                systemInfoRow("Version", "1.0.0")
                systemInfoRow("Build", "2024.1")
                systemInfoRow("Device", UIDevice.current.model)
                systemInfoRow("iOS", UIDevice.current.systemVersion)
            }
        }
    }
    
    private var aboutSection: some View {
        ModernSettingsSection(title: "ABOUT") {
            VStack(spacing: ModernDesign.Spacing.lg) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ModernDesign.Colors.holographicGradient)
                
                VStack(spacing: ModernDesign.Spacing.sm) {
                    Text("NEXUS")
                        .font(ModernDesign.Typography.displayMedium)
                        .fontWeight(.thin)
                        .foregroundStyle(ModernDesign.Colors.holographicGradient)
                        .tracking(3)
                    
                    Text("The future of tactical gaming")
                        .font(ModernDesign.Typography.bodyMedium)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Learn More") {
                    // 詳細ページへ
                }
                .buttonStyle(ModernButtonStyle(variant: .accent, size: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ModernDesign.Spacing.lg)
        }
    }
    
    private func systemInfoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(ModernDesign.Typography.bodyMedium)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(ModernDesign.Typography.bodyMedium)
                .foregroundColor(ModernDesign.Colors.textPrimary)
        }
        .padding(.horizontal, ModernDesign.Spacing.md)
    }
}

// MARK: - 設定セクション
struct ModernSettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
            Text(title)
                .font(ModernDesign.Typography.labelMedium)
                .foregroundColor(ModernDesign.Colors.textSecondary)
                .tracking(1.5)
                .textCase(.uppercase)
                .padding(.horizontal, ModernDesign.Spacing.md)
            
            content
        }
        .padding(ModernDesign.Spacing.lg)
        .glassmorphism()
        .modernBorder()
    }
}

// MARK: - トグルロウ
struct ModernToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(ModernDesign.Colors.primaryGradient)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ModernDesign.Typography.bodyMedium)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text(subtitle)
                    .font(ModernDesign.Typography.bodySmall)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .scaleEffect(0.9)
        }
        .padding(ModernDesign.Spacing.md)
        .glassmorphism(opacity: 0.1)
        .modernBorder(
            gradient: LinearGradient(
                colors: [ModernDesign.Colors.surface.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            ),
            width: 1
        )
    }
}

#Preview {
    ModernTeamSelectionView(isPresented: .constant(true))
}