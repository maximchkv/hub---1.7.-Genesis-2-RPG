import SwiftUI

struct CardLibraryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var selectedCard: ActionCardKind? = nil
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
                            // Info block with progress
                            infoBlock
                                .frame(width: contentWidth)
                            
                            // Empty state or card grid
                            if store.meta.collection.unlockedCount == 0 {
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
            .navigationTitle("Коллекция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.goToHub()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(UIStyle.Colors.inkPrimary)
                    }
                    .accessibilityLabel("Назад в Hub")
                }
            }
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card, isUnlocked: store.meta.collection.isUnlocked(card))
                    .environmentObject(store)
            }
        }
    }
    
    // MARK: - Info Block
    
    private var infoBlock: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Коллекция карт")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                Spacer()
            }
            
            // Progress
            HStack {
                Text("\(store.meta.collection.unlockedCount) / \(store.meta.collection.totalCount)")
                    .font(.headline)
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                
                Spacer()
                
                Text("разблокировано")
                    .font(.caption)
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Разблокировано \(store.meta.collection.unlockedCount) из \(store.meta.collection.totalCount) карт")
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(UIStyle.Colors.mutedFill)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(UIStyle.Colors.accent)
                        .frame(width: progressWidth(totalWidth: geo.size.width))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.meta.collection.unlockedCount)
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
        }
        .uiCard()
    }
    
    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        let total = store.meta.collection.totalCount
        guard total > 0 else { return 0 }
        let unlocked = store.meta.collection.unlockedCount
        return totalWidth * CGFloat(unlocked) / CGFloat(total)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 64))
                .foregroundStyle(UIStyle.Colors.inkSecondary.opacity(0.5))
            
            Text("Коллекция пуста")
                .font(.title2.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
            
            Text("Играйте в Tower, улучшайте карты после боев, чтобы разблокировать их в коллекции.")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Коллекция пуста. Играйте в Tower, улучшайте карты после боев, чтобы разблокировать их в коллекции.")
    }
    
    // MARK: - Card Grid
    
    private var cardGrid: some View {
        let columns = gridColumns(for: hSizeClass)
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(store.meta.collection.allCards, id: \.self) { card in
                CollectionCardCell(
                    card: card,
                    isUnlocked: store.meta.collection.isUnlocked(card)
                ) {
                    selectedCard = card
                }
            }
        }
    }
    
    // MARK: - Layout Helpers
    // widthCap удален - теперь используется UIStyle.Layout.contentWidth
    
    private func gridColumns(for sizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        // Жесткая сетка с фиксированным размером карт
        let cardWidth: CGFloat = 160
        let spacing: CGFloat = 16
        
        switch sizeClass {
        case .compact:
            // 2 columns on iPhone
            return [
                GridItem(.fixed(cardWidth), spacing: spacing),
                GridItem(.fixed(cardWidth), spacing: spacing)
            ]
        case .regular:
            // 3 columns on iPad
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
