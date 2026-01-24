import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RewardView: View {
    @EnvironmentObject private var store: GameStore

    @State private var isClaiming: Bool = false
    @State private var showConfetti: Bool = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Награда")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(UIStyle.Colors.inkPrimary)

                        Text("Выберите 1 улучшение")
                            .font(.callout)
                            .foregroundStyle(UIStyle.Colors.inkSecondary)
                    }
                    .padding(.bottom, 4)

                    // Cards
                    if let reward = store.reward {
                        VStack(spacing: 12) {
                            ForEach(reward.options, id: \.self) { kind in
                                Button {
                                    claim(kind)
                                } label: {
                                    RewardOptionCard(
                                        icon: icon(for: kind),
                                        title: title(for: kind),
                                        subtitle: "Улучшение: +1 уровень"
                                    )
                                }
                                .buttonStyle(UIStyle.CardButtonStyle())
                                .disabled(isClaiming)
                            }
                        }
                    } else {
                        Text("Награда недоступна (debug)")
                            .font(.caption)
                            .foregroundStyle(UIStyle.Colors.inkSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
            .background {
                UIStyle.background()
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            
            // Анимация конфетти
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Запускаем конфетти при появлении экрана
            showConfetti = true
        }
    }

    private func claim(_ kind: ActionCardKind) {
        guard !isClaiming else { return }
        isClaiming = true

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        withAnimation(.easeOut(duration: 0.18)) {
            store.claimReward(kind)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isClaiming = false
        }
    }

    private func title(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "Силовой удар"
        case .defend: return "Защита"
        case .doubleStrike: return "Двойной удар"
        case .counterStance: return "Стойка контратаки"
        case .bleedPlus2: return "Кровоток"
        case .weakPlus1: return "Ослабить"
        case .stun1: return "Оглушить"
        case .bleedStrike: return "Кровавый удар"
        case .weakDefend: return "Ослабляющий щит"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "???"
        }
    }

    private func icon(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "🗡️"
        case .defend: return "🛡️"
        case .doubleStrike: return "⚔️"
        case .counterStance: return "🔁"
        case .bleedPlus2: return "🩸"
        case .weakPlus1: return "⬇️"
        case .stun1: return "⚡️"
        case .bleedStrike: return "🩸⚔️"
        case .weakDefend: return "🛡️⬇️"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "❓"
        }
    }
}

private struct RewardOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(UIStyle.Colors.mutedFill)
                    .overlay(Circle().stroke(UIStyle.Colors.cardStroke, lineWidth: 1))

                Text(icon)
                    .font(.title3)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkSecondary.opacity(0.55))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
    }
}

// MARK: - Confetti Animation

private struct ConfettiView: View {
    // Параметры анимации конфетти (можно легко менять)
    private let particleCount: Int = 60           // Количество частиц конфетти
    private let animationDuration: Double = 2.5  // Длительность анимации в секундах
    private let spreadWidth: CGFloat = 400        // Ширина разброса частиц (от центра)
    private let minFallSpeed: Double = 150       // Минимальная скорость падения
    private let maxFallSpeed: Double = 300        // Максимальная скорость падения
    private let rotationSpeed: Double = 360       // Скорость вращения (градусов в секунду)
    
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                setupParticles(in: geometry.size)
                startAnimation()
            }
        }
    }
    
    private func setupParticles(in size: CGSize) {
        particles = (0..<particleCount).map { index in
            let startX = size.width / 2 + CGFloat.random(in: -spreadWidth / 2...spreadWidth / 2)
            let fallSpeed = Double.random(in: minFallSpeed...maxFallSpeed)
            let distance = Double(size.height + 100)
            let duration = distance / fallSpeed
            
            return ConfettiParticle(
                id: index,
                position: CGPoint(x: startX, y: -20),
                color: randomColor(),
                size: CGFloat.random(in: 8...14),
                opacity: Double.random(in: 0.8...1.0),
                fallSpeed: fallSpeed,
                horizontalDrift: CGFloat.random(in: -50...50),
                rotation: 0,
                rotationSpeed: Double.random(in: -rotationSpeed...rotationSpeed),
                duration: duration,
                screenHeight: size.height
            )
        }
    }
    
    private func startAnimation() {
        for index in particles.indices {
            let particle = particles[index]
            let finalY = particle.screenHeight + 100
            let finalX = particle.position.x + particle.horizontalDrift
            let finalRotation = particle.rotation + particle.rotationSpeed * particle.duration
            
            // Анимация падения и вращения одновременно
            withAnimation(.linear(duration: particle.duration)) {
                particles[index].position = CGPoint(x: finalX, y: finalY)
                particles[index].opacity = 0
                particles[index].rotation = finalRotation
            }
        }
        
        // Скрываем конфетти после завершения анимации
        let maxDuration = particles.map { $0.duration }.max() ?? animationDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + maxDuration) {
            particles = []
        }
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [
            .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
        ]
        return colors.randomElement() ?? .red
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    let fallSpeed: Double
    let horizontalDrift: CGFloat
    var rotation: Double
    let rotationSpeed: Double
    let duration: Double
    let screenHeight: CGFloat
}
