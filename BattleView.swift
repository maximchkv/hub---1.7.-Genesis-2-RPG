// TЗ-ARCH-BOOT-030 — BattleView layout v2 (Header+Bottom stack) + FIX-BOOT-030
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    // Debug layout outlines (3px) to visualize real block bounds
    private let showDebugOutlines: Bool = true

    // MARK: - Layout constants (Contract v2.0)

    // Content width cap (centered column)
    private let contentCap: CGFloat = 380
    private let outerPad: CGFloat = 0

    // Vertical spacing
    private let topHeaderPad: CGFloat = 8
    // Use one canonical spacing between major vertical blocks
    private let interBlock: CGFloat = 12 // "межлогово‑карточное расстояние"
    private var headerToParticipants: CGFloat { interBlock }
    private var participantsToLog: CGFloat { interBlock }
    private var logToCards: CGFloat { interBlock }
    private let cardsToAP: CGFloat = 12 // cards -> AP label
    private let apToButton: CGFloat = 12
    private let headerHeight: CGFloat = 52

    // Participants sizing
    // Keep participants row flush with the content column edges (per UX request).
    private let participantSideInset: CGFloat = 0

    // Log sizing (keep compact so bottom controls never fall off-screen)
    private let logMinHeight: CGFloat = 96
    private let logMaxHeight: CGFloat = 120
    private let logCorner: CGFloat = 14

    // Action cards sizing
    private let actionCardWidth: CGFloat = 120
    private let actionCardHeight: CGFloat = 170
    private let actionCardRowSpacing: CGFloat = 12

    // Disabled opacity (less aggressive than before)
    private let disabledOpacity: CGFloat = 0.70 // was 0.35

    var body: some View {
        ZStack {
            UIStyle.background()
                .ignoresSafeArea()

            GeometryReader { geo in
                let available = max(0, geo.size.width - outerPad * 2)
                let contentWidth = min(available, contentCap)

                // Participants width calculation with side inset
                let participantRowWidth = max(0, contentWidth - participantSideInset * 2)

                VStack(spacing: 0) {
                    if let battle = store.battle {
                        let isPlayerTurn = (battle.phase == .player)

                        // HEADER (debug left, floor centered, surrender right)
                        headerRow(floor: battle.floor, isPlayerTurn: isPlayerTurn)
                            .frame(width: contentWidth, alignment: .center)
                            .padding(.top, topHeaderPad)
                            .frame(height: headerHeight, alignment: .bottom)
                            .debugStroke(showDebugOutlines, .red)

                        Spacer().frame(height: headerToParticipants)
                            .debugStroke(showDebugOutlines, .red.opacity(0.6))

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
                            debug: showDebugOutlines
                        )
                        .frame(width: participantRowWidth)
                        .padding(.horizontal, participantSideInset)
                        .frame(width: contentWidth, alignment: .center)
                        .debugStroke(showDebugOutlines, .green)

                        Spacer().frame(height: participantsToLog)
                            .debugStroke(showDebugOutlines, .red.opacity(0.6))

                        // LOG (kept compact; scroll inside)
                        battleLogView
                            .frame(width: contentWidth, alignment: .center)
                            .frame(minHeight: logMinHeight)
                            .frame(maxHeight: logMaxHeight)
                            .debugStroke(showDebugOutlines, .orange)

                        // Keep a stable gap between log and the bottom area.
                        Spacer().frame(height: logToCards)
                            .debugStroke(showDebugOutlines, .red.opacity(0.6))

                        Spacer(minLength: 0)

                    } else {
                        VStack(spacing: 12) {
                            Text("No battle state")
                            Button("Back") { store.goToTower() }
                        }
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.top, 40)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, outerPad)
                .safeAreaInset(edge: .bottom) {
                    if let battle = store.battle {
                        bottomStack(contentWidth: contentWidth, battle: battle)
                            .frame(width: contentWidth, alignment: .center)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity)
                            .debugStroke(showDebugOutlines, .blue)
                    }
                }
                .debugStroke(showDebugOutlines, .purple)
            }
        }
    }

    // MARK: - Header

    private func headerRow(floor: Int, isPlayerTurn: Bool) -> some View {
        VStack(spacing: 4) {
            Text("Этаж \(floor)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(isPlayerTurn ? "Ваш ход" : "Ход врага")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isPlayerTurn ? UIStyle.Colors.accent : UIStyle.Colors.inkSecondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(isPlayerTurn ? UIStyle.Colors.accent.opacity(0.22) : Color.primary.opacity(0.08))
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                )
                .frame(maxWidth: .infinity, alignment: .center)
        }
        // Overlays DO NOT affect the view’s measured height → keeps the gap truly 12pt from the pill to participants.
        .overlay(alignment: .leading) {
            HStack(spacing: 8) {
                Button("win") { store.winBattle() }
                    .font(.caption2)
                    .buttonStyle(.bordered)

                Button("lose") { store.loseBattle() }
                    .font(.caption2)
                    .buttonStyle(.bordered)
            }
        }
        .overlay(alignment: .trailing) {
            Button {
                store.surrenderBattle()
            } label: {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(8)
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.primary.opacity(0.18), lineWidth: 1)
                    )
                    .accessibilityLabel("Surrender")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Log

    private var battleLogView: some View {
        Group {
            if let battle = store.battle {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(battle.log, id: \.id) { entry in
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
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Bottom Stack

    private func bottomStack(contentWidth: CGFloat, battle: BattleState) -> some View {
        VStack(spacing: 0) {
            actionCardsRow(battle: battle)
                .frame(width: contentWidth, alignment: .center)
                .debugStroke(showDebugOutlines, .blue.opacity(0.6))

            Spacer().frame(height: cardsToAP)
                .debugStroke(showDebugOutlines, .red.opacity(0.6))

            Text("Очки действий: \(battle.actionPoints)")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .debugStroke(showDebugOutlines, .yellow)

            Spacer().frame(height: apToButton)
                .debugStroke(showDebugOutlines, .red.opacity(0.6))

            Button("Закончить ход") { store.endTurn() }
                .buttonStyle(UIStyle.PrimaryButtonStyle())
                .disabled(battle.phase != .player)
                .opacity(battle.phase == .player ? 1.0 : 0.55)
                .debugStroke(showDebugOutlines, .pink)

            Spacer().frame(height: 2)
        }
    }

    private func actionCardsRow(battle: BattleState) -> some View {
        return VStack(spacing: 8) {
            HStack(spacing: actionCardRowSpacing) {
                ForEach(battle.hand, id: \.id) { card in
                    let hasAP = card.cost <= battle.actionPoints
                    let canPlay = hasAP
                    let lvl = battle.cardLevels[card.kind, default: 1]

                    Button {
                        store.playCard(card)
                    } label: {
                        ActionCardView(card: card, disabled: !canPlay, level: lvl)
                            .frame(width: actionCardWidth, height: actionCardHeight)
                    }
                    .disabled(!canPlay)
                    .opacity(canPlay ? 1.0 : disabledOpacity)
                    .frame(width: actionCardWidth, height: actionCardHeight)
                    .debugStroke(showDebugOutlines, .cyan)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .debugStroke(showDebugOutlines, .cyan.opacity(0.6))
        }
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
            .debugStroke(debug, .green)

            participantCard(
                name: enemyName,
                hp: enemyHP,
                block: enemyBlock,
                maxHP: enemyMaxHP,
                intentText: enemyIntent.displayRU,
                portrait: .enemy(name: enemyName)
            )
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .debugStroke(debug, .purple)
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

    private var darkGreen: Color {
        Color(red: 0.12, green: 0.45, blue: 0.20)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let ratio = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
            let fillW = max(0, min(1, ratio)) * w

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 4)
                    .fill(darkGreen)
                    .frame(width: fillW)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
