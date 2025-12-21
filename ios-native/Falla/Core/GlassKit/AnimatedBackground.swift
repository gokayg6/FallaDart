// AnimatedBackground.swift
// Falla - iOS 26 Fortune Telling App
// Animated background system with particles, parallax, and glass effects

import SwiftUI
import CoreMotion

// MARK: - Animated Background View
/// Full-screen animated background with particles and parallax motion
@available(iOS 26.0, *)
struct AnimatedBackground: View {
    // MARK: - Configuration
    let style: BackgroundStyle
    let enableParticles: Bool
    let enableParallax: Bool
    
    // MARK: - State
    @State private var gradientPhase: Double = 0
    @State private var parallaxOffset: CGSize = .zero
    @StateObject private var motionManager = MotionManager()
    
    // MARK: - Initialization
    init(
        style: BackgroundStyle = .mystical,
        enableParticles: Bool = true,
        enableParallax: Bool = true
    ) {
        self.style = style
        self.enableParticles = enableParticles
        self.enableParallax = enableParallax
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient layer with slow drift animation
                baseGradient
                    .offset(
                        x: enableParallax ? motionManager.offset.width * 20 : 0,
                        y: enableParallax ? motionManager.offset.height * 20 : 0
                    )
                
                // Frosted wave overlays
                waveOverlays(in: geometry)
                
                // Particle system
                if enableParticles {
                    ParticleEmitter(
                        particleCount: style.particleCount,
                        particleColor: style.particleColor
                    )
                }
                
                // Glass blur overlay for depth
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.1))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Start gradient drift animation
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: true)) {
                gradientPhase = 1
            }
            
            // Start motion tracking if enabled
            if enableParallax {
                motionManager.startUpdates()
            }
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
    }
    
    // MARK: - Base Gradient
    private var baseGradient: some View {
        LinearGradient(
            colors: style.gradientColors,
            startPoint: UnitPoint(
                x: 0 + sin(gradientPhase * .pi) * 0.1,
                y: 0
            ),
            endPoint: UnitPoint(
                x: 1 + cos(gradientPhase * .pi) * 0.1,
                y: 1
            )
        )
        .scaleEffect(1.2) // Oversize for parallax movement
    }
    
    // MARK: - Wave Overlays
    private func waveOverlays(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Wave 1 - Bottom
            WaveShape(
                amplitude: 30,
                frequency: 1.5,
                phase: gradientPhase * .pi * 2
            )
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.08),
                        .white.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: geometry.size.height * 0.5)
            .offset(y: geometry.size.height * 0.35)
            .offset(x: enableParallax ? motionManager.offset.width * 10 : 0)
            
            // Wave 2 - Middle
            WaveShape(
                amplitude: 25,
                frequency: 2,
                phase: gradientPhase * .pi * 2 + 1
            )
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.06),
                        .white.opacity(0.01)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: geometry.size.height * 0.6)
            .offset(y: geometry.size.height * 0.25)
            .offset(x: enableParallax ? -motionManager.offset.width * 15 : 0)
            
            // Wave 3 - Top subtle
            WaveShape(
                amplitude: 20,
                frequency: 1,
                phase: gradientPhase * .pi * 2 + 2
            )
            .fill(.white.opacity(0.04))
            .frame(height: geometry.size.height * 0.3)
            .offset(y: -geometry.size.height * 0.15)
            .offset(x: enableParallax ? motionManager.offset.width * 5 : 0)
            
            // Circular bokeh effects
            ForEach(0..<style.bokehCount, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: CGFloat.random(in: 100...200))
                    .position(
                        x: CGFloat(index) / CGFloat(style.bokehCount) * geometry.size.width + CGFloat.random(in: -50...50),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .offset(
                        x: enableParallax ? motionManager.offset.width * CGFloat(10 + index * 5) : 0,
                        y: enableParallax ? motionManager.offset.height * CGFloat(10 + index * 5) : 0
                    )
                    .blur(radius: 30)
            }
        }
    }
}

// MARK: - Background Style
/// Predefined background styles for different screens
enum BackgroundStyle {
    case mystical       // Default purple/blue mystical theme
    case warm          // Warm champagne/gold tones
    case cool          // Cool blue/cyan tones
    case cosmic        // Deep space with stars
    case dawn          // Soft pink/orange sunrise
    
    var gradientColors: [Color] {
        switch self {
        case .mystical:
            return [
                Color(red: 0.15, green: 0.08, blue: 0.25),
                Color(red: 0.12, green: 0.10, blue: 0.22),
                Color(red: 0.08, green: 0.05, blue: 0.18),
                Color(red: 0.05, green: 0.03, blue: 0.12)
            ]
        case .warm:
            return [
                Color(red: 0.25, green: 0.15, blue: 0.18),
                Color(red: 0.20, green: 0.12, blue: 0.15),
                Color(red: 0.12, green: 0.08, blue: 0.10)
            ]
        case .cool:
            return [
                Color(red: 0.08, green: 0.12, blue: 0.25),
                Color(red: 0.05, green: 0.10, blue: 0.22),
                Color(red: 0.03, green: 0.06, blue: 0.15)
            ]
        case .cosmic:
            return [
                Color(red: 0.05, green: 0.02, blue: 0.12),
                Color(red: 0.03, green: 0.01, blue: 0.08),
                Color(red: 0.02, green: 0.01, blue: 0.05)
            ]
        case .dawn:
            return [
                Color(red: 0.25, green: 0.15, blue: 0.22),
                Color(red: 0.20, green: 0.12, blue: 0.18),
                Color(red: 0.15, green: 0.10, blue: 0.15)
            ]
        }
    }
    
    var particleColor: Color {
        switch self {
        case .mystical: return .white
        case .warm: return FallaColors.champagneGold
        case .cool: return Color(red: 0.7, green: 0.9, blue: 1.0)
        case .cosmic: return .white
        case .dawn: return Color(red: 1.0, green: 0.9, blue: 0.8)
        }
    }
    
    var particleCount: Int {
        switch self {
        case .mystical: return 30
        case .warm: return 20
        case .cool: return 25
        case .cosmic: return 50
        case .dawn: return 15
        }
    }
    
    var bokehCount: Int {
        switch self {
        case .mystical: return 5
        case .warm: return 3
        case .cool: return 4
        case .cosmic: return 2
        case .dawn: return 4
        }
    }
}

// MARK: - Wave Shape
/// Animated wave shape for overlay effects
struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * .pi * 2) + phase)
            let y = (sine * amplitude) + (height * 0.5)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Particle Emitter
/// Floating particle effect for magical ambiance
@available(iOS 26.0, *)
struct ParticleEmitter: View {
    let particleCount: Int
    let particleColor: Color
    
    @State private var particles: [Particle] = []
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                for particle in particles {
                    let age = now - particle.birthTime
                    let lifetime = particle.lifetime
                    let progress = age / lifetime
                    
                    // Skip if particle has expired
                    guard progress < 1.0 else { continue }
                    
                    // Calculate fade based on age (fade in and out)
                    let fadeInDuration = 0.3
                    let fadeOutStart = 0.7
                    var opacity: Double
                    
                    if progress < fadeInDuration {
                        opacity = progress / fadeInDuration
                    } else if progress > fadeOutStart {
                        opacity = 1.0 - ((progress - fadeOutStart) / (1.0 - fadeOutStart))
                    } else {
                        opacity = 1.0
                    }
                    
                    opacity *= particle.maxOpacity
                    
                    // Calculate position with drift
                    let x = particle.startX + sin(age * particle.driftFrequency) * particle.driftAmount
                    let y = particle.startY - (age * particle.speed) // Float upward
                    
                    // Wrap y position
                    let wrappedY = y.truncatingRemainder(dividingBy: size.height + 100)
                    let finalY = wrappedY < 0 ? wrappedY + size.height + 100 : wrappedY
                    
                    // Draw particle
                    let rect = CGRect(
                        x: x - particle.size / 2,
                        y: finalY - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    
                    context.opacity = opacity
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particleColor)
                    )
                    
                    // Add glow
                    let glowRect = rect.insetBy(dx: -particle.size, dy: -particle.size)
                    context.opacity = opacity * 0.3
                    context.fill(
                        Circle().path(in: glowRect),
                        with: .color(particleColor.opacity(0.3))
                    )
                }
            }
        }
        .onAppear {
            initializeParticles()
        }
    }
    
    private func initializeParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                birthTime: Date.timeIntervalSinceReferenceDate - Double.random(in: 0...10),
                lifetime: Double.random(in: 8...15),
                startX: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                startY: CGFloat.random(in: 0...UIScreen.main.bounds.height + 100),
                size: CGFloat.random(in: 2...5),
                speed: CGFloat.random(in: 10...30),
                driftAmount: CGFloat.random(in: 20...50),
                driftFrequency: Double.random(in: 0.5...1.5),
                maxOpacity: Double.random(in: 0.3...0.7)
            )
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id = UUID()
    let birthTime: Double
    let lifetime: Double
    let startX: CGFloat
    let startY: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let driftAmount: CGFloat
    let driftFrequency: Double
    let maxOpacity: Double
}

// MARK: - Motion Manager
/// Device motion tracking for parallax effects
class MotionManager: ObservableObject {
    @Published var offset: CGSize = .zero
    
    private var motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1/60
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, _ in
            guard let motion = motion else { return }
            
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            
            DispatchQueue.main.async {
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
                    self?.offset = CGSize(
                        width: CGFloat(roll) * 50,
                        height: CGFloat(pitch) * 50
                    )
                }
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Previews
@available(iOS 26.0, *)
#Preview("Animated Background - Mystical") {
    AnimatedBackground(style: .mystical)
}

@available(iOS 26.0, *)
#Preview("Animated Background - Cosmic") {
    AnimatedBackground(style: .cosmic)
}

@available(iOS 26.0, *)
#Preview("Animated Background - Dawn") {
    AnimatedBackground(style: .dawn)
}
