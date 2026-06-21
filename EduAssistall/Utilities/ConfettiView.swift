import SwiftUI

// Phase 1: Confetti animation system for celebrations
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiParticleView(particle: particle)
                    .offset(x: particle.position.x, y: particle.position.y)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            if !isAnimating {
                startAnimation()
                isAnimating = true
            }
        }
    }
    
    private func startAnimation() {
        // Create 100 confetti particles
        particles = (0..<100).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: -200...200), y: CGFloat.random(in: -300...300)),
                velocity: CGPoint(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: -10...5)),
                rotation: CGFloat.random(in: 0...360),
                rotationSpeed: CGFloat.random(in: -10...10),
                color: [
                    Color.red, Color.blue, Color.green, Color.yellow, 
                    Color.purple, Color.orange, Color.pink, Color.cyan
                ].randomElement() ?? .blue,
                size: CGFloat.random(in: 8...16),
                opacity: 1.0
            )
        }
        
        withAnimation(.easeOut(duration: 3.0)) {
            for index in particles.indices {
                particles[index].position.x += particles[index].velocity.x * 60
                particles[index].position.y += particles[index].velocity.y * 60
                particles[index].rotation += particles[index].rotationSpeed * 60
                particles[index].opacity = 0.0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var rotation: CGFloat
    var rotationSpeed: CGFloat
    var color: Color
    var size: CGFloat
    var opacity: Double
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    
    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .rotationEffect(.degrees(particle.rotation))
    }
}

// Modifier to show confetti overlay
struct ConfettiModifier: ViewModifier {
    @State private var showConfetti = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showConfetti {
                        ConfettiView()
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showConfetti = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showConfetti = false
                        }
                    }
                }
            }
    }
}

extension View {
    func confetti() -> some View {
        self.modifier(ConfettiModifier())
    }
}

// Phase 1: Haptic feedback helper
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }
    
    static func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}

// Phase 1: Sound effects manager
class SoundEffectsManager {
    static let shared = SoundEffectsManager()
    
    private init() {}
    
    func playAchievementSound() {
        // Placeholder for sound effect - would use AVFoundation in production
        HapticFeedback.notification(.success)
    }
    
    func playLevelUpSound() {
        HapticFeedback.notification(.success)
        HapticFeedback.impact(.heavy)
    }
    
    func playBadgeUnlockSound() {
        HapticFeedback.notification(.success)
        HapticFeedback.impact(.medium)
    }
    
    func playButtonTapSound() {
        HapticFeedback.selection()
    }
    
    func playStreakSound() {
        HapticFeedback.notification(.warning)
    }
}
