import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RewardView: View {
    @EnvironmentObject private var store: GameStore

    @State private var isClaiming: Bool = false
    @State private var showConfetti: Bool = false
    @State private var showRunDeck: Bool = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Награда")
                                .font(.system(size: 28, weight: .semibold, design: .serif))
                                .foregroundStyle(UIStyle.Colors.inkPrimary)

                            Text("Выберите 1 улучшение")
                                .font(.callout)
                                .foregroundStyle(UIStyle.Colors.inkSecondary)
                        }
                        
                        Spacer()
                        
                        // Кнопка колоды забега
                        Button {
                            showRunDeck = true
                        } label: {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(UIStyle.Colors.inkPrimary)
                                .padding(10)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Колода забега")
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
                                        levelInfo: levelInfo(for: kind),
                                        bonusInfo: bonusInfo(for: kind),
                                        currentLevel: store.getCardLevelInRunDeck(kind),
                                        cost: ActionCard(kind: kind).cost
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
        .sheet(isPresented: $showRunDeck) {
            RunDeckView()
                .environmentObject(store)
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
        ActionCardTexts.title(for: kind)
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
    
    private func levelInfo(for kind: ActionCardKind) -> String {
        // Берем реальный текущий уровень из runDeck
        let currentLevel = store.getCardLevelInRunDeck(kind)
        let nextLevel = currentLevel + 1
        return "Ур.\(currentLevel) → Ур.\(nextLevel)"
    }
    
    private func bonusInfo(for kind: ActionCardKind) -> (current: String, next: String) {
        // Берем реальный текущий уровень из runDeck
        let currentLevel = store.getCardLevelInRunDeck(kind)
        let nextLevel = currentLevel + 1
        
        switch kind {
        case .powerStrike:
            let currentDamage = baseValue(level: currentLevel)
            let nextDamage = baseValue(level: nextLevel)
            return ("урон \(currentDamage)", "урон \(nextDamage)")
            
        case .defend:
            let currentBlock = baseValue(level: currentLevel)
            let nextBlock = baseValue(level: nextLevel)
            return ("блок \(currentBlock)", "блок \(nextBlock)")
            
        case .doubleStrike:
            let currentHit = Int((Double(baseValue(level: currentLevel)) * 0.8).rounded())
            let nextHit = Int((Double(baseValue(level: nextLevel)) * 0.8).rounded())
            return ("урон \(currentHit)×2", "урон \(nextHit)×2")
            
        case .counterStance:
            // Фиксированные значения, не зависят от уровня
            return ("блок 4, урон 3", "блок 4, урон 3")
            
        case .bleedPlus2:
            // Кровоток +2 всегда
            return ("кровоток +2", "кровоток +2")
            
        case .weakPlus1:
            // Слабость +1 всегда
            return ("слабость +1", "слабость +1")
            
        case .stun1:
            // Оглушение 1 всегда
            return ("оглушение 1", "оглушение 1")
            
        case .bleedStrike:
            // Если есть кровотечение: урон = стаки × 3, иначе: Кровоток +2
            // Показываем как урон от кровотечения
            return ("урон стаки×3", "урон стаки×3")
            
        case .weakDefend:
            // Слабость +1 врагу, Блок +4
            return ("слабость +1, блок +4", "слабость +1, блок +4")
            
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return ("", "")
        }
    }
    
    // Вспомогательная функция для расчета базового значения по уровню
    private func baseValue(level: Int) -> Int {
        var v = 5
        if level <= 1 { return v }
        for _ in 2...level {
            v = Int((Double(v) * 1.25).rounded())
        }
        return v
    }
}

private struct RewardOptionCard: View {
    let icon: String
    let title: String
    let levelInfo: String
    let bonusInfo: (current: String, next: String)
    let currentLevel: Int
    let cost: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(UIStyle.Colors.mutedFill)
                        .overlay(Circle().stroke(UIStyle.Colors.cardStroke, lineWidth: 1))

                    Text(icon)
                        .font(.title3)
                }
                .frame(width: 44, height: 44)
                
                // Чип с текущим уровнем
                if currentLevel > 1 {
                    Text("Lv\(currentLevel)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(UIStyle.Colors.mutedFill)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                        )
                        .offset(x: 4, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                    
                    // Стоимость в очках действия
                    Text("\(cost) ОД")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(UIStyle.Colors.mutedFill)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                        )
                }

                // Верхняя строка: информация об уровне
                Text(levelInfo)
                    .font(.caption)
                    .foregroundStyle(UIStyle.Colors.inkSecondary)

                // Нижняя строка: информация о бонусе с выделением изменяющихся элементов
                // Фиксированная высота для одной строки с уменьшением шрифта
                if !bonusInfo.current.isEmpty {
                    bonusChangeText
                        .frame(height: 16) // Фиксированная высота для одной строки
                        .lineLimit(1)
                        .minimumScaleFactor(0.5) // Уменьшение шрифта до 50% если не помещается
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkSecondary.opacity(0.55))
        }
        .padding(.vertical, 18) // Увеличена вертикальная высота
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var bonusChangeText: some View {
        let current = bonusInfo.current
        let next = bonusInfo.next
        
        if bonusInfo.current.isEmpty {
            EmptyView()
        } else {
            // Всегда показываем через стрелку с полным форматом: "блок 4, урон 3 → блок 4, урон 3"
            buildTextWithBoldNumbersAndColors(
                current: current,
                next: next
            )
        }
    }
    
    // Функция для построения текста с выделением чисел жирным и зеленым цветом, если они растут
    @ViewBuilder
    private func buildTextWithBoldNumbersAndColors(current: String, next: String) -> some View {
        // Извлекаем числа из обеих строк для сравнения
        let currentNumbers = extractNumbers(from: current)
        let nextNumbers = extractNumbers(from: next)
        
        // Обрабатываем часть до стрелки (все числа жирным)
        let beforeParts = processTextPart(current, numberIndices: [], isNextPart: false)
        
        // Обрабатываем часть после стрелки (все числа жирным, растущие - зеленым)
        let afterParts = processTextPart(next, numberIndices: getGrowingNumberIndices(current: currentNumbers, next: nextNumbers), isNextPart: true)
        
        (beforeParts.reduce(Text("")) { $0 + $1 } +
         Text(" → ") +
         afterParts.reduce(Text("")) { $0 + $1 })
            .font(.caption)
            .foregroundStyle(UIStyle.Colors.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Определяет индексы чисел, которые растут
    private func getGrowingNumberIndices(current: [Int], next: [Int]) -> Set<Int> {
        var growingIndices = Set<Int>()
        let minCount = min(current.count, next.count)
        for i in 0..<minCount {
            if next[i] > current[i] {
                growingIndices.insert(i)
            }
        }
        return growingIndices
    }
    
    // Обрабатывает часть текста, выделяя числа жирным и зеленым, если они растут
    private func processTextPart(_ text: String, numberIndices: Set<Int>, isNextPart: Bool) -> [Text] {
        var result: [Text] = []
        var i = 0
        var numberIndex = 0
        
        while i < text.count {
            let startIndex = text.index(text.startIndex, offsetBy: i)
            let char = text[startIndex]
            
            if char.isNumber {
                // Начинаем число - ищем конец числа (может содержать ×, +, -)
                var numEnd = i + 1
                while numEnd < text.count {
                    let checkIndex = text.index(text.startIndex, offsetBy: numEnd)
                    let checkChar = text[checkIndex]
                    if checkChar.isNumber || "×+-".contains(checkChar) {
                        numEnd += 1
                    } else {
                        break
                    }
                }
                
                let numRange = text.index(text.startIndex, offsetBy: i)..<text.index(text.startIndex, offsetBy: numEnd)
                let numberPart = String(text[numRange])
                
                // Выделяем жирным и зеленым, если это растущее число в части после стрелки
                if isNextPart && numberIndices.contains(numberIndex) {
                    result.append(Text(numberPart).bold().foregroundColor(UIStyle.Colors.growthGreen))
                } else {
                    result.append(Text(numberPart).bold())
                }
                numberIndex += 1
                i = numEnd
            } else {
                // Обычный символ
                result.append(Text(String(char)))
                i += 1
            }
        }
        
        return result
    }
    
    // Извлекает числа из строки (учитывает числа со знаками +, -, ×)
    private func extractNumbers(from text: String) -> [Int] {
        var numbers: [Int] = []
        var currentNumber = ""
        
        for char in text {
            if char.isNumber {
                currentNumber.append(char)
            } else if (char == "+" || char == "-") && currentNumber.isEmpty {
                // Знак в начале числа (например, +2, -1)
                currentNumber.append(char)
            } else {
                // Конец числа
                if !currentNumber.isEmpty {
                    // Убираем знаки для парсинга, но сохраняем информацию
                    let cleanNumber = currentNumber.trimmingCharacters(in: CharacterSet(charactersIn: "+-"))
                    if let num = Int(cleanNumber) {
                        numbers.append(num)
                    }
                    currentNumber = ""
                }
            }
        }
        
        // Обрабатываем последнее число
        if !currentNumber.isEmpty {
            let cleanNumber = currentNumber.trimmingCharacters(in: CharacterSet(charactersIn: "+-"))
            if let num = Int(cleanNumber) {
                numbers.append(num)
            }
        }
        
        return numbers
    }
}

// MARK: - Confetti Animation

private struct ConfettiView: View {
    // Параметры анимации конфетти (можно легко менять)
    private let particleCount: Int = 120           // Количество частиц конфетти
    private let animationDuration: Double = 2  // Длительность анимации в секундах
    private let spreadWidth: CGFloat = 500        // Ширина разброса частиц (от центра)
    private let minFallSpeed: Double = 130       // Минимальная скорость падения
    private let maxFallSpeed: Double = 260        // Максимальная скорость падения
    private let rotationSpeed: Double = 480       // Скорость вращения (градусов в секунду)
    
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
