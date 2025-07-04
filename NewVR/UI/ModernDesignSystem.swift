import SwiftUI

/// 超おしゃれなモダンデザインシステム
struct ModernDesign {
    
    // MARK: - カラーパレット（高級感のあるモダンカラー）
    struct Colors {
        // プライマリカラー
        static let primary = Color(red: 0.18, green: 0.16, blue: 0.85) // モダンブルー
        static let primaryLight = Color(red: 0.38, green: 0.36, blue: 0.95)
        static let primaryDark = Color(red: 0.08, green: 0.06, blue: 0.45)
        
        // セカンダリカラー
        static let accent = Color(red: 0.98, green: 0.42, blue: 0.69) // エレガントピンク
        static let accentLight = Color(red: 1.0, green: 0.62, blue: 0.89)
        static let accentDark = Color(red: 0.78, green: 0.22, blue: 0.49)
        
        // ニュートラルカラー
        static let background = Color(red: 0.05, green: 0.05, blue: 0.08) // リッチダーク
        static let surface = Color(red: 0.08, green: 0.08, blue: 0.12)
        static let surfaceElevated = Color(red: 0.12, green: 0.12, blue: 0.16)
        
        // テキストカラー
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.4)
        
        // アクセントカラー
        static let success = Color(red: 0.29, green: 0.94, blue: 0.61) // モダングリーン
        static let warning = Color(red: 1.0, green: 0.65, blue: 0.0) // ヴィヴィッドオレンジ
        static let error = Color(red: 1.0, green: 0.25, blue: 0.45) // スタイリッシュレッド
        
        // グラデーション
        static let primaryGradient = LinearGradient(
            colors: [primaryLight, primary, primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [accentLight, accent, accentDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let backgroundGradient = LinearGradient(
            colors: [background, surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // ホログラフィックグラデーション
        static let holographicGradient = LinearGradient(
            colors: [
                Color(red: 0.8, green: 0.2, blue: 1.0),
                Color(red: 0.2, green: 0.8, blue: 1.0),
                Color(red: 1.0, green: 0.4, blue: 0.8),
                Color(red: 0.6, green: 1.0, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - タイポグラフィ（洗練されたフォント階層）
    struct Typography {
        static let displayLarge = Font.system(size: 42, weight: .thin, design: .default)
        static let displayMedium = Font.system(size: 36, weight: .ultraLight, design: .default)
        static let displaySmall = Font.system(size: 28, weight: .light, design: .default)
        
        static let headlineLarge = Font.system(size: 24, weight: .medium, design: .default)
        static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
        static let headlineSmall = Font.system(size: 18, weight: .bold, design: .default)
        
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .medium, design: .default)
        
        static let labelLarge = Font.system(size: 14, weight: .semibold, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 10, weight: .bold, design: .default)
    }
    
    // MARK: - スペーシング
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - コーナー半径
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    // MARK: - シャドウ
    struct Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let glow = (color: ModernDesign.Colors.primary.opacity(0.3), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(0))
    }
}

// MARK: - グラスモーフィズムエフェクト
struct GlassmorphismEffect: ViewModifier {
    let tintColor: Color
    let opacity: Double
    let blurRadius: CGFloat
    
    init(tintColor: Color = ModernDesign.Colors.surface, opacity: Double = 0.3, blurRadius: CGFloat = 20) {
        self.tintColor = tintColor
        self.opacity = opacity
        self.blurRadius = blurRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(tintColor.opacity(opacity))
                    .background(.ultraThinMaterial, in: Rectangle())
                    .blur(radius: 0.5)
            )
            .overlay(
                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - モダングラデーションボーダー
struct ModernBorder: ViewModifier {
    let gradient: LinearGradient
    let width: CGFloat
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(gradient, lineWidth: width)
            )
    }
}

// MARK: - フローティングアニメーション
struct FloatingAnimation: ViewModifier {
    @State private var isFloating = false
    let duration: Double
    let offset: CGFloat
    
    init(duration: Double = 3.0, offset: CGFloat = 10) {
        self.duration = duration
        self.offset = offset
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -offset : offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating.toggle()
                }
            }
    }
}

// MARK: - パーティクルエフェクト
struct ParticleEffect: View {
    @State private var particles: [Particle] = []
    let particleCount: Int
    
    init(particleCount: Int = 50) {
        self.particleCount = particleCount
    }
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ModernDesign.Colors.primary.opacity(particle.opacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }
    
    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.1...0.6)
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.x += CGFloat.random(in: -1...1)
                particles[i].position.y += CGFloat.random(in: -1...1)
                particles[i].opacity = Double.random(in: 0.1...0.6)
                
                // 画面外に出たら反対側から出現
                if particles[i].position.x < 0 {
                    particles[i].position.x = UIScreen.main.bounds.width
                } else if particles[i].position.x > UIScreen.main.bounds.width {
                    particles[i].position.x = 0
                }
                
                if particles[i].position.y < 0 {
                    particles[i].position.y = UIScreen.main.bounds.height
                } else if particles[i].position.y > UIScreen.main.bounds.height {
                    particles[i].position.y = 0
                }
            }
        }
    }
}

struct Particle {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
}

// MARK: - ニューモーフィズム（ソフトUI）
struct NeumorphismEffect: ViewModifier {
    let isPressed: Bool
    let lightShadowColor: Color
    let darkShadowColor: Color
    
    init(isPressed: Bool = false) {
        self.isPressed = isPressed
        self.lightShadowColor = Color.white.opacity(0.1)
        self.darkShadowColor = Color.black.opacity(0.3)
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.medium)
                    .fill(ModernDesign.Colors.surface)
                    .shadow(
                        color: isPressed ? darkShadowColor : lightShadowColor,
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? 2 : -4,
                        y: isPressed ? 2 : -4
                    )
                    .shadow(
                        color: isPressed ? lightShadowColor : darkShadowColor,
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? -2 : 4,
                        y: isPressed ? -2 : 4
                    )
            )
    }
}

// MARK: - View Extensions
extension View {
    func glassmorphism(
        tintColor: Color = ModernDesign.Colors.surface,
        opacity: Double = 0.3,
        blurRadius: CGFloat = 20
    ) -> some View {
        modifier(GlassmorphismEffect(tintColor: tintColor, opacity: opacity, blurRadius: blurRadius))
    }
    
    func modernBorder(
        gradient: LinearGradient = ModernDesign.Colors.primaryGradient,
        width: CGFloat = 2,
        cornerRadius: CGFloat = ModernDesign.CornerRadius.medium
    ) -> some View {
        modifier(ModernBorder(gradient: gradient, width: width, cornerRadius: cornerRadius))
    }
    
    func floating(duration: Double = 3.0, offset: CGFloat = 10) -> some View {
        modifier(FloatingAnimation(duration: duration, offset: offset))
    }
    
    func neumorphism(isPressed: Bool = false) -> some View {
        modifier(NeumorphismEffect(isPressed: isPressed))
    }
    
    func modernShadow(_ shadowType: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = ModernDesign.Shadow.medium) -> some View {
        shadow(color: shadowType.color, radius: shadowType.radius, x: shadowType.x, y: shadowType.y)
    }
    
    func modernBackground() -> some View {
        background(
            ZStack {
                ModernDesign.Colors.backgroundGradient
                    .ignoresSafeArea()
                
                ParticleEffect(particleCount: 30)
                    .opacity(0.6)
                    .ignoresSafeArea()
            }
        )
    }
}

// MARK: - モダンボタンスタイル
struct ModernButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    let size: ButtonSize
    
    enum ButtonVariant {
        case primary, secondary, accent, ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return ModernDesign.Colors.primary
            case .secondary: return ModernDesign.Colors.surface
            case .accent: return ModernDesign.Colors.accent
            case .ghost: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .accent: return Color.white
            case .secondary: return ModernDesign.Colors.textPrimary
            case .ghost: return ModernDesign.Colors.primary
            }
        }
    }
    
    enum ButtonSize {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            case .large: return EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return ModernDesign.Typography.labelSmall
            case .medium: return ModernDesign.Typography.labelMedium
            case .large: return ModernDesign.Typography.labelLarge
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(variant.foregroundColor)
            .padding(size.padding)
            .background(
                ZStack {
                    if variant == .primary {
                        RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.medium)
                            .fill(ModernDesign.Colors.primaryGradient)
                    } else {
                        RoundedRectangle(cornerRadius: ModernDesign.CornerRadius.medium)
                            .fill(variant.backgroundColor)
                    }
                }
            )
            .glassmorphism()
            .modernShadow(configuration.isPressed ? ModernDesign.Shadow.small : ModernDesign.Shadow.medium)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}