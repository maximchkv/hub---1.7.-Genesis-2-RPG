// TЗ-ARCH-BOOT-030 — BattleView layout v3 (Redesigned: statuses, collapsible log, improved cards)
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showDrawPile: Bool = false
    @State private var showDiscardPile: Bool = false

    // Debug layout outlines (3px) to visualize real block bounds
    private let showDebugOutlines: Bool = false

    // MARK: - Layout constants (Contract v3.0)

    // Content width cap (centered column)
    private let contentCap: CGFloat = 380
    private let outerPad: CGFloat = UIStyle.Spacing.s // 8px боковые отступы

    // Vertical spacing - стандартизировано через UI Kit
    private let topHeaderPad: CGFloat = UIStyle.Spacing.s
    private let interBlock: CGFloat = UIStyle.Spacing.m // Стандартные отступы между блоками
    private var headerToParticipants: CGFloat { interBlock }
    private var participantsToLog: CGFloat { interBlock }
    private var logToCards: CGFloat { interBlock }
    private let cardsToButton: CGFloat = UIStyle.Spacing.m
    private let headerHeight: CGFloat = 22


    // Log sizing (always visible, ~1/3 longer than before)
    private let logFixedHeight: CGFloat = 80 // Увеличено примерно на треть (было 60)
    private let logCorner: CGFloat = 14

    // Action cards sizing (improved readability)
    // Базовые размеры для расчета пропорций
    private let actionCardBaseWidth: CGFloat = 160
    private let actionCardBaseHeight: CGFloat = 220
    private let actionCardRowSpacing: CGFloat = UIStyle.Spacing.m
    private let maxCardsInRow: Int = 3 // Максимальное количество карточек в ряду

    // Disabled opacity
    private let disabledOpacity: CGFloat = 0.70

    var body: some View {
        UIStyle.Layout.ScreenContainer {
            GeometryReader { geo in
                // Используем ContentWidthProvider для расчета ширины
                let contentWidth = UIStyle.Layout.contentWidth(
                    geometry: geo,
                    horizontalPadding: outerPad,
                    sizeClass: nil
                )
                // Применяем специфичный кап для BattleView
                let finalContentWidth = min(contentWidth, contentCap)

                VStack(spacing: 0) {
                    if let battle = store.battle {
                        let isPlayerTurn = (battle.phase == .player)

                        // БЛОК 1: HEADER - ограничен по ширине как карточки
                        headerRow(floor: battle.floor, isPlayerTurn: isPlayerTurn)
                            .frame(width: finalContentWidth)
                            .frame(height: headerHeight)
                            .frame(maxWidth: .infinity)
                            .padding(.top, topHeaderPad)

                        Spacer().frame(height: headerToParticipants)

                        // БЛОК 2: PARTICIPANTS (with statuses) - ограничены по ширине как карточки
                        ParticipantsPanel(
                            playerName: "Игрок",
                            playerHP: battle.playerHP,
                            playerBlock: battle.playerBlock,
                            playerMaxHP: 20,
                            playerStatuses: battle.playerStatuses,
                            playerActionPoints: battle.actionPoints,
                            enemyName: battle.enemyName,
                            enemyHP: battle.enemyHP,
                            enemyBlock: battle.enemyBlock,
                            enemyMaxHP: 20,
                            enemyStatuses: battle.enemyStatuses,
                            enemyIntent: battle.enemyIntent,
                            playerShakeTrigger: store.playerShakeTrigger,
                            enemyShakeTrigger: store.enemyShakeTrigger,
                            debug: showDebugOutlines
                        )
                        .frame(width: finalContentWidth)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.blue, lineWidth: 3)
                                .opacity(showDebugOutlines ? 1 : 0)
                        )

                        Spacer().frame(height: participantsToLog)

                        // БЛОК 3: LOG (always visible, fixed height 80px) - ограничен по ширине как карточки
                        compactLogView(battle: battle)
                            .frame(width: finalContentWidth)
                            .frame(height: logFixedHeight)
                            .frame(maxWidth: .infinity)

                        // Минимальный отступ между логом и карточками
                        Spacer().frame(height: logToCards)

                        // БЛОК 4: CARDS area - занимает все доступное пространство
                        VStack(spacing: 0) {
                            // Карточки - занимают все оставшееся пространство
                            GeometryReader { cardsGeo in
                                let availableHeight = cardsGeo.size.height
                                
                                actionCardsRow(
                                    battle: battle,
                                    contentWidth: finalContentWidth,
                                    availableHeight: availableHeight
                                )
                            }
                            
                            Spacer().frame(height: cardsToButton)
                            
                            // БЛОК 5: Compact AP + End Turn button - ограничены по ширине как карточки
                            compactBottomControls(battle: battle, contentWidth: finalContentWidth)
                                .frame(width: finalContentWidth)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.bottom, UIStyle.Spacing.m)

                    } else {
                        VStack(spacing: UIStyle.Spacing.m) {
                            Text("No battle state")
                            Button("Back") { store.goToTower() }
                        }
                        .frame(width: finalContentWidth, alignment: .center)
                        .padding(.top, 40)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, outerPad)
            }
        }
    }

    // MARK: - Header

    private func headerRow(floor: Int, isPlayerTurn: Bool) -> some View {
        ZStack {
            Text("Этаж \(floor)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            HStack {
                HStack(spacing: 6) {
                    Button("win") { store.winBattle() }
                        .font(.system(size: 11, weight: .semibold))
                        .buttonStyle(.bordered)
                        .controlSize(.mini)

                    Button("lose") { store.loseBattle() }
                        .font(.system(size: 11, weight: .semibold))
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                }

                Spacer(minLength: 0)

                Button {
                    store.surrenderBattle()
                } label: {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(4)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.primary.opacity(0.18), lineWidth: 1)
                        )
                        .frame(width: 30, height: 30)
                        .accessibilityLabel("Surrender")
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Log (Always visible, compact - 3 lines)

    @ViewBuilder
    private func compactLogView(battle: BattleState) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(battle.log, id: \.id) { entry in
                        logEntryView(entry: entry)
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id("LOG_BOTTOM")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(height: logFixedHeight) // Ограничиваем высоту для компактности
            .onChange(of: battle.log.count) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("LOG_BOTTOM", anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo("LOG_BOTTOM", anchor: .bottom)
            }
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: logCorner))
        .overlay(
            RoundedRectangle(cornerRadius: logCorner)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: logCorner)
                .stroke(Color.purple, lineWidth: 3)
                .opacity(showDebugOutlines ? 1 : 0)
        )
    }
    
    @ViewBuilder
    private func logEntryView(entry: CombatLogEntry) -> some View {
        if entry.kind == .separator || entry.text == "__DIVIDER__" {
            Divider()
                .padding(.vertical, 6)
                .id(entry.id)
        } else {
            Text(entry.text)
                .font(.caption2)
                .fontWeight(entry.isPlayer ? .bold : .regular)
                .foregroundStyle(entry.kind == .system ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(entry.id)
        }
    }

    // MARK: - Bottom Controls

    private func compactBottomControls(battle: BattleState, contentWidth: CGFloat) -> some View {
        let controlHeight: CGFloat = 18  // Уменьшено в 2 раза (было 36)
        let containerSize: CGFloat = 50
        
        return HStack(spacing: UIStyle.Spacing.m) {
            // Left: Draw pile container
            drawPileContainer(battle: battle, size: containerSize)
            
            // Center: End turn button (reduced size)
            Button {
                store.endTurn()
            } label: {
                Text("Закончить ход")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: controlHeight)
                    .background(
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius)
                            .fill(UIStyle.Colors.accent)
                    )
            }
            .buttonStyle(.plain)
            .disabled(battle.phase != .player)
            .opacity(battle.phase == .player ? 1.0 : 0.55)
            
            // Right: Discard pile container
            discardPileContainer(battle: battle, size: containerSize)
        }
        .frame(width: contentWidth)
        .sheet(isPresented: $showDrawPile) {
            DrawPileView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showDiscardPile) {
            DiscardPileView()
                .environmentObject(store)
        }
    }
    
    private func drawPileContainer(battle: BattleState, size: CGFloat) -> some View {
        let count = battle.drawPile.count
        
        return Button {
            showDrawPile = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
            }
            .frame(width: size, height: size)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func discardPileContainer(battle: BattleState, size: CGFloat) -> some View {
        let count = battle.discardPile.count
        
        return Button {
            showDiscardPile = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
            }
            .frame(width: size, height: size)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func compactAPIndicator(ap: Int) -> some View {
        let chipShape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        
        return HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundStyle(UIStyle.Colors.inkSecondary)
            
            Text("\(ap)")
                .font(.headline)
                .foregroundStyle(UIStyle.Colors.inkPrimary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: chipShape)
        .overlay(
            chipShape.stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
        .frame(width: 60)
    }

    private func actionCardsRow(battle: BattleState, contentWidth: CGFloat, availableHeight: CGFloat) -> some View {
        // Вычисляем размер карточек так, чтобы maxCardsInRow карточек поместились по ширине
        let cardCount = min(battle.hand.count, maxCardsInRow)
        let spacingTotal = CGFloat(max(0, cardCount - 1)) * actionCardRowSpacing
        let availableWidth = contentWidth - spacingTotal
        let calculatedCardWidth = availableWidth / CGFloat(cardCount)
        
        // Высота карточек адаптивная - используем все доступное пространство
        let cardHeight = availableHeight
        
        return HStack(spacing: actionCardRowSpacing) {
            ForEach(battle.hand.prefix(maxCardsInRow), id: \.id) { card in
                let cardState = determineCardState(card: card, battle: battle)
                let lvl = card.level  // Use level from card itself

                Button {
                    store.playCard(card)
                } label: {
                    ActionCardView(card: card, state: cardState, level: lvl)
                        .frame(width: calculatedCardWidth, height: cardHeight)
                }
                .buttonStyle(.plain)
                .disabled(cardState != .available)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func determineCardState(card: ActionCard, battle: BattleState) -> CardPlayabilityState {
        // Проверка фазы
        guard battle.phase == .player else {
            return .notPlayerTurn
        }
        
        // Проверка, была ли карта уже использована
        if battle.usedCardsThisTurn.contains(card.kind) {
            return .alreadyUsed
        }
        
        // Проверка очков действий
        if battle.actionPoints < card.cost {
            return .insufficientAP
        }
        
        return .available
    }
}

// MARK: - Debug outline helper
extension View {
    @ViewBuilder
    func debugStroke(_ enabled: Bool, _ color: Color) -> some View {
        #if DEBUG
        if enabled {
            self.overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(color, lineWidth: 3)
            )
        } else {
            self
        }
        #else
        self
        #endif
    }
}

// MARK: - Participants panel (rebuilt layout)

private struct ParticipantsPanel: View {
    let playerName: String
    let playerHP: Int
    let playerBlock: Int
    let playerMaxHP: Int
    let playerStatuses: [StatusInstance]
    let playerActionPoints: Int

    let enemyName: String
    let enemyHP: Int
    let enemyBlock: Int
    let enemyMaxHP: Int
    let enemyStatuses: [StatusInstance]
    let enemyIntent: EnemyIntent
    let playerShakeTrigger: Int
    let enemyShakeTrigger: Int
    let debug: Bool

    private let corner: CGFloat = 16
    private let innerPad: CGFloat = 12
    private let rowGap: CGFloat = 10
    private let dividerH: CGFloat = 1
    private let interCardGap: CGFloat = 24
    private let portraitCorner: CGFloat = 14
    private let statusChipHeight: CGFloat = 16 // Уменьшено для компактности
    private let statusContainerHeight: CGFloat = 35 // Фиксированная высота для 2 рядов по 2 статуса: (16 * 2) + (3 * 1) = 35

    var body: some View {
        HStack(alignment: .top, spacing: interCardGap) {
            participantCard(
                name: playerName,
                hp: playerHP,
                block: playerBlock,
                maxHP: playerMaxHP,
                statuses: playerStatuses,
                intent: nil,
                actionPoints: playerActionPoints,
                portrait: .player,
                shakeTrigger: playerShakeTrigger
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)

            participantCard(
                name: enemyName,
                hp: enemyHP,
                block: enemyBlock,
                maxHP: enemyMaxHP,
                statuses: enemyStatuses,
                intent: enemyIntent,
                actionPoints: nil,
                portrait: .enemy(name: enemyName),
                shakeTrigger: enemyShakeTrigger
            )
            .frame(maxWidth: .infinity, alignment: .topTrailing)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private enum PortraitKind {
        case player
        case enemy(name: String)
    }

    private func participantCard(
        name: String,
        hp: Int,
        block: Int,
        maxHP: Int,
        statuses: [StatusInstance],
        intent: EnemyIntent?,
        actionPoints: Int?,
        portrait: PortraitKind,
        shakeTrigger: Int
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner)

        return participantColumn(
            name: name,
            hp: hp,
            block: block,
            maxHP: maxHP,
            statuses: statuses,
            intent: intent,
            actionPoints: actionPoints,
            portrait: portrait,
            shakeTrigger: shakeTrigger,
            debug: debug
        )
        .padding(innerPad)
        .background(.thinMaterial, in: shape)
        .overlay(shape.stroke(UIStyle.Colors.cardStroke, lineWidth: 1))
        .overlay(
            shape.stroke(Color.red, lineWidth: 3)
                .opacity(debug ? 1 : 0)
        )
    }

    private func participantColumn(
        name: String,
        hp: Int,
        block: Int,
        maxHP: Int,
        statuses: [StatusInstance],
        intent: EnemyIntent?,
        actionPoints: Int?,
        portrait: PortraitKind,
        shakeTrigger: Int,
        debug: Bool
    ) -> some View {
        VStack(spacing: rowGap) {
            // 1) Name
            Text(name)
                .font(.headline)
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.orange, lineWidth: 2)
                        .opacity(debug ? 1 : 0)
                )

            // 2) HP and Block combined block (фиксированная высота 48px, контент адаптивный)
            HPBlockStatsView(hp: hp, maxHP: maxHP, block: block, debug: debug)
                .frame(height: 48)
                .frame(maxWidth: .infinity)

            // 3) Intent or Action Points (перемещено перед статусами)
            Group {
                if let intent {
                    // Враг: показываем интент с SF Symbol иконкой
                    intentBlock(intent: intent)
                } else if let actionPoints = actionPoints {
                    // Игрок: показываем очки действия
                    actionPointsBlock(ap: actionPoints)
                } else {
                    // Пустой блок для совместимости
                    Text(" ")
                        .font(.caption2.weight(.semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .opacity(0)
                }
            }
            .frame(height: 24) // Фиксированная высота вместо minHeight
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.yellow, lineWidth: 2)
                    .opacity(debug ? 1 : 0)
            )

            // 4) Statuses (NEW) - фиксированная высота для 2 рядов по 2 статуса с заливкой
            statusesView(statuses: statuses)
                .frame(height: statusContainerHeight) // Фиксированная высота
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(UIStyle.Colors.mutedFill) // Заливка по UI-гайду
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.cyan, lineWidth: 2)
                        .opacity(debug ? 1 : 0)
                )

            // 7) Portrait (square) with shake animation
            portraitView(portrait, shakeTrigger: shakeTrigger)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: portraitCorner)
                        .stroke(Color.pink, lineWidth: 2)
                        .opacity(debug ? 1 : 0)
                )
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Statuses View
    
    @ViewBuilder
    private func statusesView(statuses: [StatusInstance]) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 3),
            GridItem(.flexible(), spacing: 3)
        ], spacing: 3) {
            ForEach(statuses) { status in
                statusChip(status: status)
            }
        }
    }
    
    private func statusChip(status: StatusInstance) -> some View {
        HStack(spacing: 3) {
            // Иконка статуса (уменьшена)
            Image(systemName: status.type.iconName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(status.type.iconColor)
            
            // Количество стаков (уменьшен шрифт)
            Text("\(status.stacks)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(height: statusChipHeight)
        .frame(maxWidth: .infinity)
        .background(UIStyle.Colors.mutedFill)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
    }

    // MARK: - Action Points Block
    
    private func actionPointsBlock(ap: Int) -> some View {
        HStack(spacing: 6) {
            Text("Очки ОД:")
                .font(.caption2.weight(.medium))
                .foregroundStyle(UIStyle.Colors.inkSecondary)
            
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.yellow)
            
            Text("\(ap)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UIStyle.Colors.mutedFill)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
    }
    
    // MARK: - Intent Block (такой же формат как Action Points)
    
    private func intentBlock(intent: EnemyIntent) -> some View {
        HStack(spacing: 6) {
            Text("Собирается:")
                .font(.caption2.weight(.medium))
                .foregroundStyle(UIStyle.Colors.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6) // Уменьшение шрифта если не помещается
            
            // SF Symbol иконка (синхронизировано с карточками)
            Image(systemName: intent.iconName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(intent.iconColor)
                .imageScale(.medium)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 12, height: 12) // Фиксированный размер иконки
            
            // Текст интента (всегда в одну строку с уменьшением шрифта)
            Text(intent.displayText)
                .font(.caption2.weight(.bold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.4) // Агрессивное уменьшение для текста интента
                .fixedSize(horizontal: false, vertical: true) // Разрешаем горизонтальное сжатие
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UIStyle.Colors.mutedFill)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func portraitView(_ kind: PortraitKind, shakeTrigger: Int) -> some View {
        PortraitShakeView(kind: kind, shakeTrigger: shakeTrigger, portraitCorner: portraitCorner, enemyPortraitAssetName: enemyPortraitAssetName)
    }
    
    // Отдельный View для анимации дрожания с правильной обработкой изменений
    private struct PortraitShakeView: View {
        let kind: PortraitKind
        let shakeTrigger: Int
        let portraitCorner: CGFloat
        let enemyPortraitAssetName: (String) -> String?
        
        // Параметры анимации дрожания (можно легко менять)
        private let shakeAmplitude: CGFloat = 10  // Амплитуда колебаний (размах): от -12 до +12 пикселей
        private let shakeDuration: Double = 0.12 // Длительность одного колебания в секундах
        
        @State private var shakeX: CGFloat = 0
        @State private var shakeY: CGFloat = 0
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: portraitCorner)
                    .strokeBorder(UIStyle.Colors.cardStroke, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: portraitCorner)
                            .fill(UIStyle.Colors.mutedFill)
                    )

                switch kind {
                case .player:
                    Image("player")
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: portraitCorner))
                case .enemy(let name):
                    if let asset = enemyPortraitAssetName(name) {
                        Image(asset)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: portraitCorner))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .offset(x: shakeX, y: shakeY) // Отдельные смещения по X и Y для более заметного дрожания
            .onChange(of: shakeTrigger) { newValue in
                // Запускаем анимацию каждый раз при изменении триггера
                guard newValue > 0 else {
                    // Сбрасываем смещение, если триггер сброшен
                    withAnimation {
                        shakeX = 0
                        shakeY = 0
                    }
                    return
                }
                
                // Генерируем новое случайное смещение для каждого триггера
                // Используем параметр shakeAmplitude для амплитуды
                let seed = UInt64(newValue)
                var state = seed
                state = state &* 1103515245 &+ 12345
                let range = Int(shakeAmplitude * 2) + 1 // Диапазон от -amplitude до +amplitude
                let xOffset = CGFloat(Int(state) % range) - shakeAmplitude
                
                state = state &* 1103515245 &+ 12345
                let yOffset = CGFloat(Int(state) % range) - shakeAmplitude
                
                // Сбрасываем перед новой анимацией
                shakeX = 0
                shakeY = 0
                
                // Используем параметр shakeDuration для длительности
                let repeatCount: Int = 6 // Количество повторений
                
                // Запускаем анимацию дрожания с настраиваемыми параметрами
                withAnimation(.easeInOut(duration: shakeDuration).repeatCount(repeatCount, autoreverses: true)) {
                    shakeX = xOffset
                    shakeY = yOffset
                }
                
                // Сбрасываем смещение после завершения анимации
                DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * Double(repeatCount)) {
                    withAnimation {
                        shakeX = 0
                        shakeY = 0
                    }
                }
            }
            .clipped()
        }
    }

    private func enemyPortraitAssetName(for name: String) -> String? {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "феянча": return "feyancha"
        case "графитовый голем": return "graphite_golem"
        case "каратель": return "punisher"
        case "монахи зесуруми": return "zesurumi_monks"
        default: return nil
        }
    }
}

// MARK: - HP and Block Stats Block (фиксированная высота 48px, контент адаптивный)

private struct HPBlockStatsView: View {
    let hp: Int
    let maxHP: Int
    let block: Int
    let debug: Bool
    
    private let fixedHeight: CGFloat = 48

    var body: some View {
        GeometryReader { geo in
            let availableHeight = geo.size.height
            
            // Адаптивные размеры на основе фиксированной высоты 48px
            let iconSize = max(12, min(18, availableHeight * 0.35))
            let fontSize = max(10, min(14, availableHeight * 0.28))
            let spacing = max(2, min(5, availableHeight * 0.1))
            
            HStack(spacing: 0) {
                // Left column: HP with heart icon
                VStack(spacing: spacing) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundStyle(UIStyle.Colors.hpGreen)
                        .minimumScaleFactor(0.5)
                    
                    Text("\(hp)/\(maxHP)")
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                
                // Divider between columns
                Rectangle()
                    .fill(UIStyle.Colors.cardStroke)
                    .frame(width: 1)
                
                // Right column: Block with shield icon
                VStack(spacing: spacing) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundStyle(UIStyle.Colors.inkSecondary)
                        .minimumScaleFactor(0.5)
                    
                    Text("\(block)")
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            }
        }
        .frame(height: fixedHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.blue, lineWidth: 2)
                .opacity(debug ? 1 : 0)
        )
    }
}
