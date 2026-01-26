import SwiftUI

struct DiscardPileView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var selectedCard: ActionCard? = nil
    @State private var hasAppeared: Bool = false
    
    // Layout constants
    private let horizontalPadding: CGFloat = UIStyle.Spacing.xl
    private let verticalPadding: CGFloat = UIStyle.Spacing.xl
    
    var body: some View {
        NavigationStack {
            UIStyle.Layout.ScreenContainer {
                GeometryReader { geo in
                    let contentWidth = UIStyle.Layout.contentWidth(
                        geometry: geo,
                        horizontalPadding: horizontalPadding,
                        sizeClass: hSizeClass
                    )
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            infoBlock
                                .frame(width: contentWidth)
                            
                            if discardPileCards.isEmpty {
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
            .navigationTitle("Стопка сброса")
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
    
    private var discardPileCards: [ActionCard] {
        store.battle?.discardPile ?? []
    }
    
    private var groupedCards: [(kind: ActionCardKind, cards: [ActionCard])] {
        let grouped = Dictionary(grouping: discardPileCards) { $0.kind }
        return grouped.map { (kind: $0.key, cards: $0.value) }
            .sorted { $0.kind.rawValue < $1.kind.rawValue }
    }
    
    private var infoBlock: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Стопка сброса")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                Spacer()
            }
            
            HStack {
                Text("\(discardPileCards.count) карт")
                    .font(.headline)
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                Spacer()
            }
        }
        .uiCard()
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash")
                .font(.system(size: 64))
                .foregroundStyle(UIStyle.Colors.inkSecondary.opacity(0.5))
            
            Text("Стопка сброса пуста")
                .font(.title2.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
            
            Text("Разыграйте карты, чтобы они появились здесь.")
                .font(.body)
                .foregroundStyle(UIStyle.Colors.inkSecondary)
                .multilineTextAlignment(.center)
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
    
    private var cardGrid: some View {
        let columns = gridColumns(for: hSizeClass)
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(groupedCards, id: \.kind) { group in
                RunDeckCardCell(
                    cards: group.cards,
                    kind: group.kind
                ) { card in
                    selectedCard = card
                }
            }
        }
    }
    
    private func gridColumns(for sizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        // Жесткая сетка с фиксированным размером карт
        let cardWidth: CGFloat = 160
        let spacing: CGFloat = 16
        
        switch sizeClass {
        case .compact:
            return [
                GridItem(.fixed(cardWidth), spacing: spacing),
                GridItem(.fixed(cardWidth), spacing: spacing)
            ]
        case .regular:
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
