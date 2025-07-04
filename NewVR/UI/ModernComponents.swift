import SwiftUI
import MapKit
import CoreLocation

// MARK: - 超おしゃれなヘルスバー
struct ModernHealthBar: View {
    let currentHealth: Int
    let maxHealth: Int
    @State private var animationProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200
    
    private var healthPercentage: Double {
        Double(currentHealth) / Double(maxHealth)
    }
    
    private var healthGradient: LinearGradient {
        switch healthPercentage {
        case 0.7...1.0:
            return LinearGradient(
                colors: [ModernDesign.Colors.success, Color(red: 0.4, green: 1.0, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 0.3..<0.7:
            return LinearGradient(
                colors: [ModernDesign.Colors.warning, Color(red: 1.0, green: 0.8, blue: 0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [ModernDesign.Colors.error, Color(red: 1.0, green: 0.5, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HEALTH")
                        .font(ModernDesign.Typography.labelSmall)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentHealth)")
                            .font(ModernDesign.Typography.displayMedium)
                            .fontWeight(.thin)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                            .scaleEffect(pulseScale)
                        
                        Text("/ \(maxHealth)")
                            .font(ModernDesign.Typography.bodyMedium)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // ヘルス状態インジケーター
                VStack(spacing: 8) {
                    Circle()
                        .fill(healthGradient)
                        .frame(width: 12, height: 12)
                        .scaleEffect(pulseScale)
                        .modernShadow(ModernDesign.Shadow.glow)
                    
                    Text("\(Int(healthPercentage * 100))%")
                        .font(ModernDesign.Typography.labelMedium)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
            }
            
            // プログレスバー
            ZStack(alignment: .leading) {
                // ベース
                RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.large)
                    .fill(ModernDesign.Colors.surface)
                    .frame(height: 32)
                    .glassmorphism(opacity: 0.1)
                
                // プログレス
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.large)
                        .fill(healthGradient)
                        .frame(width: geometry.size.width * animationProgress)
                        .overlay(
                            // シマーエフェクト
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.white.opacity(0.6),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80)
                                .offset(x: shimmerOffset)
                                .blur(radius: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.large))
                        .modernShadow((
                            color: getHealthGradientBaseColor().opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 0
                        ))
                }
                .frame(height: 32)
            }
        }
        .padding(ModernDesign.Spacing.lg)
        .glassmorphism()
        .modernBorder()
        .onAppear {
            updateAnimation()
        }
        .onChange(of: currentHealth) { _ in
            updateAnimation()
        }
    }
    
    private func updateAnimation() {
        withAnimation(.easeOut(duration: 1.0)) {
            animationProgress = healthPercentage
        }
        
        // パルス効果
        if healthPercentage < 0.3 {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        } else {
            pulseScale = 1.0
        }
        
        // シマーエフェクト
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 300
        }
    }
    
    private func getHealthGradientBaseColor() -> Color {
        switch healthPercentage {
        case 0.7...1.0:
            return ModernDesign.Colors.success
        case 0.3..<0.7:
            return ModernDesign.Colors.warning
        default:
            return ModernDesign.Colors.error
        }
    }
}

// MARK: - 超おしゃれなマップビュー
struct ModernMapView: View {
    @ObservedObject var viewModel: MapLocationViewModelEnhanced
    @State private var selectedMode: MapDisplayMode = .teammateOnly
    @State private var isExpanded = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // マップヘッダー
            mapHeader
            
            // メインマップ
            ZStack {
                if let region = viewModel.region {
                    Map(coordinateRegion: .constant(region), annotationItems: viewModel.userLocations) { location in
                        MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                            ModernPlayerMarker(location: location)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.medium))
                } else {
                    ModernLoadingView()
                }
                
                // フローティングコントロール
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingControls
                    }
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .glassmorphism()
        .modernBorder()
    }
    
    private var mapHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TACTICAL VIEW")
                    .font(ModernDesign.Typography.labelSmall)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.5)
                
                Text(selectedMode.description)
                    .font(ModernDesign.Typography.headlineSmall)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
            }
            
            Spacer()
            
            // 統計情報
            HStack(spacing: ModernDesign.Spacing.lg) {
                statCard(
                    title: "ALLIES",
                    count: viewModel.userLocations.filter { $0.isTeammate }.count,
                    color: ModernDesign.Colors.success
                )
                
                if selectedMode != .teammateOnly {
                    statCard(
                        title: "HOSTILES",
                        count: viewModel.userLocations.filter { !$0.isTeammate }.count,
                        color: ModernDesign.Colors.error
                    )
                }
            }
        }
        .padding(ModernDesign.Spacing.lg)
    }
    
    private func statCard(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(ModernDesign.Typography.headlineMedium)
                .fontWeight(.thin)
                .foregroundColor(color)
            
            Text(title)
                .font(ModernDesign.Typography.labelSmall)
                .foregroundColor(ModernDesign.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(1)
        }
        .padding(.horizontal, ModernDesign.Spacing.md)
        .padding(.vertical, ModernDesign.Spacing.sm)
        .glassmorphism(opacity: 0.1)
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.small)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var floatingControls: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            // 表示モード切り替え
            Button(action: { toggleDisplayMode() }) {
                Image(systemName: getDisplayModeIcon())
                    .font(.title2)
                    .foregroundColor(ModernDesign.Colors.primary)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(ModernButtonStyle(variant: .ghost, size: .medium))
            .glassmorphism()
            .rotationEffect(.degrees(rotationAngle))
            
            // 拡大/縮小
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                Image(systemName: isExpanded ? "minus.magnifyingglass" : "plus.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(ModernDesign.Colors.accent)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(ModernButtonStyle(variant: .ghost, size: .medium))
            .glassmorphism()
        }
    }
    
    private func toggleDisplayMode() {
        withAnimation(.spring()) {
            rotationAngle += 120
            switch selectedMode {
            case .teammateOnly:
                selectedMode = .teammateWithDelayed
            case .teammateWithDelayed:
                selectedMode = .teammateWithRadar
            case .teammateWithRadar:
                selectedMode = .teammateOnly
            }
            viewModel.displayMode = selectedMode
        }
    }
    
    private func getDisplayModeIcon() -> String {
        switch selectedMode {
        case .teammateOnly:
            return "person.2.fill"
        case .teammateWithDelayed:
            return "clock.fill"
        case .teammateWithRadar:
            return "radar"
        }
    }
}

// MARK: - 超おしゃれなプレイヤーマーカー
struct ModernPlayerMarker: View {
    let location: EnhancedLocationData
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var glowIntensity: Double = 0.5
    
    private var markerGradient: LinearGradient {
        if location.isTeammate {
            return LinearGradient(
                colors: [ModernDesign.Colors.success, ModernDesign.Colors.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if location.isDelayed {
            return LinearGradient(
                colors: [ModernDesign.Colors.warning, ModernDesign.Colors.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [ModernDesign.Colors.error, ModernDesign.Colors.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            // 外側のリング
            Circle()
                .stroke(markerGradient, lineWidth: 2)
                .frame(width: 60, height: 60)
                .scaleEffect(pulseScale)
                .opacity(0.6)
            
            // メインマーカー
            Circle()
                .fill(markerGradient)
                .frame(width: 32, height: 32)
                .glassmorphism()
                .modernShadow((
                    color: getMarkerBaseColor().opacity(glowIntensity),
                    radius: 12,
                    x: 0,
                    y: 0
                ))
            
            // アイコン
            Image(systemName: location.isTeammate ? "shield.fill" : (location.isDelayed ? "clock.fill" : "target"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotationAngle))
            
            // 情報パネル
            VStack(spacing: 2) {
                Spacer()
                
                Text(location.username.prefix(6))
                    .font(ModernDesign.Typography.labelSmall)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                
                Text("HP: \(location.hp)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .offset(y: 40)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // パルスアニメーション
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.4
        }
        
        // 回転アニメーション（敵のみ）
        if !location.isTeammate {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
        
        // グローエフェクト
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
    
    private func getMarkerBaseColor() -> Color {
        if location.isTeammate {
            return ModernDesign.Colors.success
        } else if location.isDelayed {
            return ModernDesign.Colors.warning
        } else {
            return ModernDesign.Colors.error
        }
    }
}

// MARK: - 超おしゃれなローディングビュー
struct ModernLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.7
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.xl) {
            // メインローダー
            ZStack {
                // 外側のリング
                Circle()
                    .stroke(
                        ModernDesign.Colors.primaryGradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [20, 10])
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotationAngle))
                
                // 内側のリング
                Circle()
                    .stroke(
                        ModernDesign.Colors.accentGradient,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [10, 5])
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-rotationAngle * 1.5))
                
                // 中央のパルス
                Circle()
                    .fill(ModernDesign.Colors.holographicGradient)
                    .frame(width: 40, height: 40)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            .modernShadow(ModernDesign.Shadow.glow)
            
            // テキスト
            VStack(spacing: ModernDesign.Spacing.sm) {
                Text("ESTABLISHING CONNECTION")
                    .font(ModernDesign.Typography.headlineSmall)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                    .textCase(.uppercase)
                    .tracking(2)
                
                Text("Synchronizing tactical data...")
                    .font(ModernDesign.Typography.bodyMedium)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .opacity(opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modernBackground()
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scale = 1.2
            opacity = 1.0
        }
    }
}

// MARK: - 超おしゃれなコネクションステータス
struct ModernConnectionStatus: View {
    @ObservedObject var bleViewModel: BleViewModel
    @State private var pulseScale: CGFloat = 1.0
    
    private var statusColor: Color {
        bleViewModel.isConnected ? ModernDesign.Colors.success : ModernDesign.Colors.error
    }
    
    private var statusGradient: LinearGradient {
        LinearGradient(
            colors: [statusColor, statusColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            // ステータスインジケーター
            Circle()
                .fill(statusGradient)
                .frame(width: 16, height: 16)
                .scaleEffect(pulseScale)
                .modernShadow((
                    color: statusColor.opacity(0.6),
                    radius: 8,
                    x: 0,
                    y: 0
                ))
            
            // ステータステキスト
            VStack(alignment: .leading, spacing: 2) {
                Text("CONNECTION")
                    .font(ModernDesign.Typography.labelSmall)
                    .foregroundColor(ModernDesign.Colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(bleViewModel.connectionStatus)
                    .font(ModernDesign.Typography.bodyMedium)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
            }
            
            Spacer()
            
            // デバイス数
            if bleViewModel.discoveredDevicesCount > 0 {
                Text("\(bleViewModel.discoveredDevicesCount)")
                    .font(ModernDesign.Typography.headlineSmall)
                    .foregroundColor(ModernDesign.Colors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ModernDesign.Colors.accent.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(ModernDesign.Spacing.lg)
        .glassmorphism()
        .modernBorder()
        .onAppear {
            startPulse()
        }
        .onChange(of: bleViewModel.isConnected) { _ in
            startPulse()
        }
    }
    
    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = bleViewModel.isConnected ? 1.2 : 1.4
        }
    }
}
