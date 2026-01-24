// TЗ-ARCH-BOOT-030 — BattleView layout v2 (Header+Bottom stack) + FIX-BOOT-030
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    // Debug layout outlines (3px) to visualize real block bounds
    private let showDebugOutlines: Bool = false

    // MARK: - Layout constants (Contract v2.0)

    // Content width cap (centered column)
    private let contentCap: CGFloat = 380
    private let outerPad: CGFloat = 0

    // Vertical spacing - стандартизировано через UI Kit
    private let topHeaderPad: CGFloat = UIStyle.Spacing.s
    // Use one canonical spacing between major vertical blocks
    private let interBlock: CGFloat = UIStyle.Spacing.m // "межлогово‑карточное расстояние"
    private var headerToParticipants: CGFloat { interBlock }
    private var participantsToLog: CGFloat { interBlock }
    private var logToCards: CGFloat { interBlock }
    private let cardsToAP: CGFloat = UIStyle.Spacing.m // cards -> AP label
    private let apToButton: CGFloat = UIStyle.Spacing.m
    // Reduced by ~1/3 (was 52) to free vertical space for participants.
    private let headerHeight: CGFloat = 22

    // Participants sizing
    // Keep participants row flush with the content column edges (per UX request).
    private let participantSideInset: CGFloat = 0

    // Log sizing (keep compact so bottom controls never fall off-screen)
    private let logMinHeight: CGFloat = 104
    private let logMaxHeight: CGFloat = 132
    private let logCorner: CGFloat = 14

    // Action cards sizing
    private let actionCardWidth: CGFloat = 120
    // Card height: 134 = 122 (VStack content + spacing) + 12 (padding)
    private let actionCardHeight: CGFloat = 180
    private let actionCardRowSpacing: CGFloat = UIStyle.Spacing.m

    // Disabled opacity (less aggressive than before)
    private let disabledOpacity: CGFloat = 0.70 // was 0.35

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
                // Intentionally not using safe-area bottom inset here: bottom controls are pinned to the bottom edge.

                        // Participants width calculation with side inset
                let participantRowWidth = max(0, finalContentWidth - participantSideInset * 2)

                VStack(spacing: 0) {
                    if let battle = store.battle {
                        let isPlayerTurn = (battle.phase == .player)

                        // HEADER (debug left, floor centered, surrender right)
                        headerRow(floor: battle.floor, isPlayerTurn: isPlayerTurn)
                            .frame(width: finalContentWidth, alignment: .center)
                            .frame(height: headerHeight, alignment: .center)
                            .padding(.top, topHeaderPad)

                        Spacer().frame(height: headerToParticipants)

                        // PARTICIPANTS (rebuilt from scratch)
                        ParticipantsPanel(
                            playerName: "Игрок",
                            playerHP: battle.playerHP,
                            playerBlock: battle.playerBlock,
                            playerMaxHP: 20,
                            enemyName: battle.enemyName,
                            enemyHP: battle.enemyHP,
                            enemyBlock: battle.enemyBlock,
                            enemyMaxHP: 20,
                            enemyIntent: battle.enemyIntent,
                            debug: false
                        )
                        .frame(width: participantRowWidth)
                        .padding(.horizontal, participantSideInset)
                        .frame(width: finalContentWidth, alignment: .center)

                        Spacer().frame(height: participantsToLog)

                        // LOG (kept compact; scroll inside)
                        battleLogView
                            .frame(width: finalContentWidth, alignment: .center)
                            .frame(minHeight: logMinHeight)
                            .frame(maxHeight: logMaxHeight)

                        // Keep a stable gap between log and the bottom area.
                        Spacer().frame(height: logToCards)

                        // Spacer to push bottom controls to the bottom
                        Spacer()
                        
                        // Bottom controls pinned to the bottom edge
                        bottomStack(contentWidth: finalContentWidth, battle: battle)
                            .frame(width: finalContentWidth, alignment: .center)

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
                .padding(.bottom, 0)
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

    // MARK: - Log

    @ViewBuilder
    private var battleLogView: some View {
        if let battle = store.battle {
            logScrollView(battle: battle)
        } else {
            EmptyView()
        }
    }
    
    private func logScrollView(battle: BattleState) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(battle.log, id: \.id) { entry in
                        logEntryView(entry: entry)
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id("LOG_BOTTOM")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: battle.log.count) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("LOG_BOTTOM", anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo("LOG_BOTTOM", anchor: .bottom)
            }
        }
        .padding(8)
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

    // MARK: - Bottom Stack

    private func bottomStack(contentWidth: CGFloat, battle: BattleState) -> some View {
        VStack(spacing: 0) {
            actionCardsRow(battle: battle)
                .frame(width: contentWidth, alignment: .center) // contentWidth здесь - это параметр функции

            Spacer().frame(height: cardsToAP)

            apPanel(ap: battle.actionPoints)
                .frame(maxWidth: .infinity, alignment: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange, lineWidth: 3)
                        .opacity(showDebugOutlines ? 1 : 0)
                )

            Spacer().frame(height: apToButton)

            Button("Закончить ход") { store.endTurn() }
                .buttonStyle(UIStyle.PrimaryButtonStyle())
                .disabled(battle.phase != .player)
                .opacity(battle.phase == .player ? 1.0 : 0.55)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green, lineWidth: 3)
                        .opacity(showDebugOutlines ? 1 : 0)
                )
        }
    }

    private func apPanel(ap: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14)
        let chipShape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        return HStack(spacing: 10) {
            Text("Очки действий:")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(UIStyle.Colors.inkPrimary)

            Spacer(minLength: 0)

            Text("\(ap) ОД")
                .font(.caption) // slightly smaller, not bold
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(UIStyle.Colors.mutedFill, in: chipShape)
                .overlay(
                    chipShape.stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12) // left inset for label, right inset for chip
        .frame(width: actionCardWidth * 2) // x2 width (per UX request)
        .background(.thinMaterial, in: shape)
        .overlay(shape.stroke(UIStyle.Colors.cardStroke, lineWidth: 1))
    }

    private func actionCardsRow(battle: BattleState) -> some View {
        return HStack(spacing: actionCardRowSpacing) {
            ForEach(battle.hand, id: \.id) { card in
                let cardState = determineCardState(card: card, battle: battle)
                let lvl = battle.cardLevels[card.kind, default: 1]

                Button {
                    store.playCard(card)
                } label: {
                    ActionCardView(card: card, state: cardState, level: lvl)
                        .frame(width: actionCardWidth, height: actionCardHeight)
                }
                .buttonStyle(.plain) // Убираем стандартные отступы Button
                .disabled(cardState != .available)
                .frame(width: actionCardWidth, height: actionCardHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: actionCardHeight) // Точная высота = высоте карточек (134)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cyan, lineWidth: 3)
                .opacity(showDebugOutlines ? 1 : 0)
        )
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

    let enemyName: String
    let enemyHP: Int
    let enemyBlock: Int
    let enemyMaxHP: Int
    let enemyIntent: EnemyIntent
    let debug: Bool

    private let corner: CGFloat = 16
    private let innerPad: CGFloat = 12
    private let rowGap: CGFloat = 10
    private let dividerH: CGFloat = 1
    // Larger gap so cards read as two distinct panels and hug the outer edges more.
    private let interCardGap: CGFloat = 24
    private let portraitCorner: CGFloat = 14

    var body: some View {
        HStack(alignment: .top, spacing: interCardGap) {
            participantCard(
                name: playerName,
                hp: playerHP,
                block: playerBlock,
                maxHP: playerMaxHP,
                intentText: nil,
                portrait: .player
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)

            participantCard(
                name: enemyName,
                hp: enemyHP,
                block: enemyBlock,
                maxHP: enemyMaxHP,
                intentText: enemyIntent.displayRU,
                portrait: .enemy(name: enemyName)
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
        intentText: String?,
        portrait: PortraitKind
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner)

        return participantColumn(
            name: name,
            hp: hp,
            block: block,
            maxHP: maxHP,
            intentText: intentText,
            portrait: portrait
        )
        .padding(innerPad)
        .background(.thinMaterial, in: shape)
        .overlay(shape.stroke(UIStyle.Colors.cardStroke, lineWidth: 1))
    }

    private func participantColumn(
        name: String,
        hp: Int,
        block: Int,
        maxHP: Int,
        intentText: String?,
        portrait: PortraitKind
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

            // 2) HP bar
            HPBar(value: hp, maxValue: maxHP)
                .frame(height: 6)

            // 3) Stats
            VStack(spacing: 2) {
                Text("HP: \(hp)/\(maxHP)")
                    .font(.caption2)
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
                Text("Блок: \(block)")
                    .font(.caption2)
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
            }
            .frame(maxWidth: .infinity)

            // 4) Divider
            Rectangle()
                .fill(UIStyle.Colors.cardStroke)
                .frame(height: dividerH)

            // 5) Intent (player empty)
            Group {
                if let intentText {
                    Text(intentText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(UIStyle.Colors.mutedFill)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                        )
                } else {
                    Text(" ")
                        .font(.caption2.weight(.semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .opacity(0)
                }
            }
            .frame(height: 24)

            // 6) Portrait (square)
            portraitView(portrait)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func portraitView(_ kind: PortraitKind) -> some View {
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
                if let asset = enemyPortraitAssetName(for: name) {
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
        .clipped()
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

// MARK: - HP Bar (dark green)

private struct HPBar: View {
    let value: Int
    let maxValue: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let ratio = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
            let fillW = max(0, min(1, ratio)) * w

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 4)
                    .fill(UIStyle.Colors.hpGreen)
                    .frame(width: fillW)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
