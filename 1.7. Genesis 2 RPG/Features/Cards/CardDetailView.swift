import SwiftUI

struct CardDetailView: View {
    let card: ActionCardKind
    let isUnlocked: Bool
    let currentLevel: Int?  // Текущий уровень карты в забеге (для подсветки)
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameStore
    
    init(card: ActionCardKind, isUnlocked: Bool, currentLevel: Int? = nil) {
        self.card = card
        self.isUnlocked = isUnlocked
        self.currentLevel = currentLevel
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Section
                    heroSection
                    
                    // Base Info
                    baseInfoSection
                    
                    // Level Progression
                    if isUnlocked && !card.isPlaceholder {
                        levelProgressionSection
                    }
                    
                    // Statistics
                    if isUnlocked && !card.isPlaceholder {
                        statisticsSection
                    }
                    
                    // Locked state message
                    if !isUnlocked || card.isPlaceholder {
                        lockedStateSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .background(
                UIStyle.background()
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(UIStyle.Colors.inkPrimary)
                    }
                    .accessibilityLabel("Закрыть")
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.thinMaterial, for: .navigationBar)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? UIStyle.Colors.mutedFill : Color.black.opacity(0.7))
                    .frame(width: 100, height: 100)
                
                if isUnlocked {
                    Text(icon)
                        .font(.system(size: 60))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Text(isUnlocked ? titleRU : "???")
                .font(.title2.weight(.bold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Base Info
    
    private var baseInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Описание")
                .font(.headline)
                .foregroundStyle(UIStyle.Colors.inkPrimary)
            
            Text(isUnlocked ? effectRU : "Заблокированная карта. Играйте в Tower, чтобы разблокировать.")
                .font(.body)
                .foregroundStyle(UIStyle.Colors.inkSecondary)
            
            if isUnlocked {
                HStack {
                    Label("\(cost) ОД", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .uiCard()
    }
    
    // MARK: - Level Progression
    
    private var levelProgressionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Значения по уровням")
                .font(.headline)
                .foregroundStyle(UIStyle.Colors.inkPrimary)
            
            VStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    levelRow(level: level)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .uiCard()
    }
    
    private func levelRow(level: Int) -> some View {
        let isCurrentLevel = currentLevel == level
        
        return HStack {
            Text("Lv\(level)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isCurrentLevel ? UIStyle.Colors.accent : UIStyle.Colors.inkPrimary)
                .frame(width: 50, alignment: .leading)
            
            Text(levelEffect(level: level))
                .font(.subheadline)
                .foregroundStyle(isCurrentLevel ? UIStyle.Colors.accent : UIStyle.Colors.inkSecondary)
            
            Spacer()
            
            if isCurrentLevel {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(UIStyle.Colors.accent)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, isCurrentLevel ? 8 : 0)
        .background(isCurrentLevel ? UIStyle.Colors.accent.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private func levelEffect(level: Int) -> String {
        switch card {
        case .powerStrike:
            let dmg = powerStrikeDamage(level: level)
            return "Урон: \(dmg)"
        case .defend:
            let block = defendBlock(level: level)
            return "Блок: \(block)"
        case .doubleStrike:
            let hit = doubleStrikeHit(level: level)
            return "Урон: \(hit) × 2"
        case .counterStance:
            let block = counterStanceBlockValue()
            let dmg = counterStanceAttackValue()
            return "Блок: \(block), Урон: \(dmg)"
        case .bleedPlus2:
            return "Кровоток +2"
        case .weakPlus1:
            return "Слабость +1"
        case .stun1:
            return "Оглушение 1"
        case .bleedStrike:
            return "Если Кровоток: урон = стаки × 3. Иначе: Кровоток +2"
        case .weakDefend:
            return "Слабость +1 врагу, Блок +4"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "???"
        }
    }
    
    // MARK: - Statistics
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика")
                .font(.headline)
                .foregroundStyle(UIStyle.Colors.inkPrimary)
            
            let stats = store.meta.collection.stats(for: card)
            
            HStack {
                Image(systemName: "play.circle")
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
                Text("Использовано раз:")
                    .font(.subheadline)
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
                Spacer()
                Text("\(stats.timesUsed)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .uiCard()
    }
    
    // MARK: - Locked State
    
    private var lockedStateSection: some View {
        VStack(spacing: 12) {
            Image(systemName: card.isPlaceholder ? "questionmark.circle" : "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(UIStyle.Colors.inkSecondary.opacity(0.5))
            
            Text(card.isPlaceholder ? "Скоро появится" : "Карта заблокирована")
                .font(.headline)
                .foregroundStyle(UIStyle.Colors.inkPrimary)
            
            Text(card.isPlaceholder ? 
                "Эта карта появится в будущих обновлениях игры. Следите за новостями!" :
                "Улучшайте карты после боев в Tower, чтобы разблокировать их в коллекции.")
                .font(.subheadline)
                .foregroundStyle(UIStyle.Colors.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .uiCard()
    }
    
    // MARK: - Helpers (copied from GameStore for card calculations)
    
    private func baseValue(level: Int) -> Int {
        var v = 5
        if level <= 1 { return v }
        for _ in 2...level {
            v = Int((Double(v) * 1.25).rounded())
        }
        return v
    }
    
    private func powerStrikeDamage(level: Int) -> Int { baseValue(level: level) }
    private func defendBlock(level: Int) -> Int { baseValue(level: level) }
    private func doubleStrikeHit(level: Int) -> Int { Int((Double(powerStrikeDamage(level: level)) * 0.8).rounded()) }
    private func counterStanceBlockValue() -> Int { 4 }
    private func counterStanceAttackValue() -> Int { 3 }
    
    // MARK: - Card Properties
    
    private var titleRU: String {
        ActionCardTexts.title(for: card)
    }
    
    private var icon: String {
        switch card {
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
    
    private var effectRU: String {
        ActionCardTexts.detailedDescription(for: card)
    }
    
    private var cost: Int {
        switch card {
        case .powerStrike: return 1
        case .defend: return 1
        case .doubleStrike: return 2
        case .counterStance: return 2
        case .bleedPlus2: return 1
        case .weakPlus1: return 1
        case .stun1: return 2
        case .bleedStrike: return 2
        case .weakDefend: return 2
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return 0
        }
    }
}
