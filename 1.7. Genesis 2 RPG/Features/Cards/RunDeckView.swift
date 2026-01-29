import SwiftUI

struct RunDeckView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var selectedCard: ActionCard? = nil
    @State private var hasAppeared: Bool = false
    
    // Layout constants - стандартизировано через UI Kit
    private let horizontalPadding: CGFloat = UIStyle.Spacing.xl
    private let verticalPadding: CGFloat = UIStyle.Spacing.xl
    
    var body: some View {
        NavigationStack {
            UIStyle.Layout.ScreenContainer {
                GeometryReader { geo in
                    // Используем ContentWidthProvider для расчета ширины
                    let contentWidth = UIStyle.Layout.contentWidth(
                        geometry: geo,
                        horizontalPadding: horizontalPadding,
                        sizeClass: hSizeClass
                    )
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Info block
                            infoBlock
                                .frame(width: contentWidth)
                            
                            // Empty state or card grid
                            if deckCards.isEmpty {
                                emptyState
                                    .frame(width: contentWidth)
                            } else {
                                cardGrid
                                    .frame(width: contentWidth)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, UIStyle.Spacing.s)
                        .padding(.bottom, verticalPadding)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 20)
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.3)) {
                            hasAppeared = true
                        }
                    }
                }
            }
            .navigationTitle("Колода забега")
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
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: Binding(
                get: { selectedCard?.kind },
                set: { _ in selectedCard = nil }
            )) { cardKind in
                if let card = selectedCard {
                    CardDetailView(
                        card: cardKind,
                        isUnlocked: true,
                        currentLevel: card.level
                    )
                    .environmentObject(store)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var deckCards: [ActionCard] {
        store.run?.runDeck ?? []
    }
    
    // Show each card separately (each has unique ID)
    private var sortedCards: [ActionCard] {
        deckCards.sorted { $0.kind.rawValue < $1.kind.rawValue }
    }
    
    // MARK: - Info Block
    
    private var infoBlock: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Колода забега")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(UIStyle.Colors.textOnCard)
                Spacer()
            }
            
            // Card count
            HStack {
                Text("\(deckCards.count) карт")
                    .font(.headline)
                    .foregroundStyle(UIStyle.Colors.textOnCard)
                
                Spacer()
            }
        }
        .uiCard()
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 64))
                .foregroundStyle(UIStyle.Colors.inkSecondary.opacity(0.5))
            
            Text("Колода пуста")
                .font(.title2.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
            
            Text("Начните новый забег, чтобы получить стартовую колоду.")
                .font(.body)
                .foregroundStyle(UIStyle.Colors.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
    }
    
    // MARK: - Card Grid
    
    private var cardGrid: some View {
        let columns = gridColumns(for: hSizeClass)
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(sortedCards, id: \.id) { card in
                RunDeckCardCell(
                    cards: [card],
                    kind: card.kind
                ) { selectedCard in
                    self.selectedCard = selectedCard
                }
            }
        }
    }
    
    // MARK: - Layout Helpers
    
    private func gridColumns(for sizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        // Жесткая сетка с фиксированным размером карт
        let cardWidth: CGFloat = 160  // Фиксированная ширина карты
        let spacing: CGFloat = 16
        
        switch sizeClass {
        case .compact:
            // 2 колонки на iPhone
            return [
                GridItem(.fixed(cardWidth), spacing: spacing),
                GridItem(.fixed(cardWidth), spacing: spacing)
            ]
        case .regular:
            // 3 колонки на iPad
            return [
                GridItem(.fixed(cardWidth), spacing: spacing),
                GridItem(.fixed(cardWidth), spacing: spacing),
                GridItem(.fixed(cardWidth), spacing: spacing)
            ]
        default:
            return [
                GridItem(.fixed(cardWidth), spacing: spacing),
                GridItem(.fixed(cardWidth), spacing: spacing)
            ]
        }
    }
}

// MARK: - Run Deck Card Cell

struct RunDeckCardCell: View {
    let cards: [ActionCard]  // Обычно одна карта, но оставляем массив для совместимости
    let kind: ActionCardKind
    let onTap: (ActionCard) -> Void
    
    // Фиксированный размер карты
    private let cardWidth: CGFloat = 160
    private let cardHeight: CGFloat = 200
    
    private var card: ActionCard {
        cards.first!  // Всегда одна карта теперь
    }
    
    var body: some View {
        Button {
            onTap(card)
        } label: {
            VStack(spacing: 8) {
                // Icon - фиксированный размер
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(UIStyle.Colors.mutedFill)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(iconColor)
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 80, height: 80)  // Фиксированный размер иконки
                
                // Title - масштабируется
                Text(ActionCardTexts.title(for: kind))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(height: 36)
                
                // Level info - масштабируется
                Text("Lv\(card.level)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(UIStyle.Colors.accent)
                
                // Cost - масштабируется
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                    Text("\(card.cost)")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(UIStyle.Colors.inkSecondary)
            }
            .padding(12)
            .frame(width: cardWidth, height: cardHeight)  // Фиксированный размер карты
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Icon System (синхронизировано с ActionCardView и CollectionCardCell)
    
    private var icon: String {
        switch kind {
        // Базовые карты
        case .powerStrike: return "flame.fill"
        case .defend: return "shield.fill"
        case .doubleStrike: return "arrow.triangle.2.circlepath"
        case .counterStance: return "arrow.counterclockwise.circle.fill"
        
        // Статусные карты
        case .bleedPlus2: return "drop.fill"
        case .weakPlus1: return "arrow.down.circle.fill"
        case .stun1: return "bolt.fill"
        
        // Синергийные карты
        case .bleedStrike: return "drop.fill"
        case .weakDefend: return "shield.fill"
        
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "questionmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch kind {
        case .bleedPlus2, .bleedStrike: return Color.red
        case .weakPlus1, .weakDefend: return Color.orange
        case .stun1: return Color.purple
        default: return UIStyle.Colors.inkPrimary
        }
    }
}
