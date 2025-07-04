import SwiftUI
import UIKit

/// レーザーゲーム風デザインシステム
struct LaserGameDesign {
    
    // MARK: - カラーパレット
    struct Colors {
        // ネオンカラー
        static let neonBlue = Color(red: 0.0, green: 0.8, blue: 1.0)
        static let neonRed = Color(red: 1.0, green: 0.1, blue: 0.3)
        static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.4)
        static let neonOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
        static let neonPurple = Color(red: 0.8, green: 0.2, blue: 1.0)
        static let neonYellow = Color(red: 1.0, green: 1.0, blue: 0.0)
        
        // ダークテーマ
        static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
        static let darkSecondary = Color(red: 0.1, green: 0.1, blue: 0.15)
        static let darkAccent = Color(red: 0.15, green: 0.15, blue: 0.2)
        
        // レーザー効果
        static let laserCore = Color.white
        static let laserGlow = Color.cyan
        
        // 警告・危険
        static let warning = neonOrange
        static let danger = neonRed
        static let success = neonGreen
        
        // チーム色（強化版）
        static let teamRed = Color(red: 0.9, green: 0.1, blue: 0.2)
        static let teamBlue = Color(red: 0.1, green: 0.4, blue: 1.0)
        static let teamGreen = Color(red: 0.1, green: 0.8, blue: 0.3)
        static let teamYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
        static let teamOrange = Color(red: 1.0, green: 0.4, blue: 0.0)
    }
    
    // MARK: - タイポグラフィ
    struct Typography {
        static let title = Font.system(size: 28, weight: .black, design: .monospaced)
        static let subtitle = Font.system(size: 20, weight: .bold, design: .monospaced)
        static let body = Font.system(size: 16, weight: .semibold, design: .monospaced)
        static let caption = Font.system(size: 12, weight: .medium, design: .monospaced)
        static let hud = Font.system(size: 14, weight: .heavy, design: .monospaced)
    }
    
    // MARK: - レーザーボーダー
    struct LaserBorder: ViewModifier {
        let color: Color
        let width: CGFloat
        let cornerRadius: CGFloat
        
        func body(content: Content) -> some View {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), color, color.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: width
                        )
                        .shadow(color: color, radius: width * 2)
                )
        }
    }
    
    // MARK: - ネオングロー
    struct NeonGlow: ViewModifier {
        let color: Color
        let radius: CGFloat
        
        func body(content: Content) -> some View {
            content
                .shadow(color: color, radius: radius * 0.5)
                .shadow(color: color, radius: radius)
                .shadow(color: color, radius: radius * 1.5)
        }
    }
    
    // MARK: - ホログラム効果
    struct HologramEffect: ViewModifier {
        @State private var phase: Double = 0
        
        func body(content: Content) -> some View {
            content
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Colors.neonBlue.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.7)
                    .animation(
                        Animation.linear(duration: 2.0).repeatForever(autoreverses: false),
                        value: phase
                    )
                )
                .onAppear {
                    phase = 1.0
                }
        }
    }
    
    // MARK: - スキャンライン
    struct ScanLine: View {
        @State private var offset: CGFloat = -200
        let color: Color
        
        var body: some View {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            color.opacity(0.8),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: offset)
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
                    ) {
                        offset = 200
                    }
                }
        }
    }
}

// MARK: - View Extensions
extension View {
    func laserBorder(color: Color = LaserGameDesign.Colors.neonBlue, width: CGFloat = 2, cornerRadius: CGFloat = 8) -> some View {
        modifier(LaserGameDesign.LaserBorder(color: color, width: width, cornerRadius: cornerRadius))
    }
    
    func neonGlow(color: Color = LaserGameDesign.Colors.neonBlue, radius: CGFloat = 4) -> some View {
        modifier(LaserGameDesign.NeonGlow(color: color, radius: radius))
    }
    
    func hologramEffect() -> some View {
        modifier(LaserGameDesign.HologramEffect())
    }
    
    func tacticalBackground() -> some View {
        background(
            ZStack {
                LaserGameDesign.Colors.darkBackground
                
                // グリッドパターン
                Path { path in
                    let spacing: CGFloat = 20
                    for i in stride(from: 0, through: 400, by: spacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i, y: 400))
                        path.move(to: CGPoint(x: 0, y: i))
                        path.addLine(to: CGPoint(x: 400, y: i))
                    }
                }
                .stroke(LaserGameDesign.Colors.neonBlue.opacity(0.1), lineWidth: 0.5)
            }
        )
    }
}

// MARK: - カスタムボタンスタイル
struct LaserButtonStyle: ButtonStyle {
    let color: Color
    let isActive: Bool
    
    init(color: Color = LaserGameDesign.Colors.neonBlue, isActive: Bool = true) {
        self.color = color
        self.isActive = isActive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LaserGameDesign.Typography.body)
            .foregroundColor(isActive ? color : color.opacity(0.5))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    LaserGameDesign.Colors.darkSecondary
                    
                    if configuration.isPressed {
                        color.opacity(0.2)
                    }
                }
            )
            .laserBorder(color: isActive ? color : color.opacity(0.3))
            .neonGlow(color: isActive ? color : Color.clear, radius: configuration.isPressed ? 8 : 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - HUDコンテナ
struct HUDContainer<Content: View>: View {
    let content: Content
    let title: String?
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(LaserGameDesign.Typography.caption)
                        .foregroundColor(LaserGameDesign.Colors.neonBlue)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    // ステータスインジケーター
                    Circle()
                        .fill(LaserGameDesign.Colors.neonGreen)
                        .frame(width: 6, height: 6)
                        .neonGlow(color: LaserGameDesign.Colors.neonGreen, radius: 2)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                Divider()
                    .background(LaserGameDesign.Colors.neonBlue.opacity(0.3))
            }
            
            content
                .padding(12)
        }
        .background(LaserGameDesign.Colors.darkSecondary.opacity(0.9))
        .laserBorder(color: LaserGameDesign.Colors.neonBlue, width: 1, cornerRadius: 6)
        .overlay(
            LaserGameDesign.ScanLine(color: LaserGameDesign.Colors.neonBlue)
                .clipped()
        )
    }
}