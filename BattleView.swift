// TЗ-ARCH-BOOT-030 — BattleView layout v2 (Header+Bottom stack) + FIX-BOOT-030
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    // MARK: - Layout constants (Contract v2.0)

    // Content width cap (centered column)
    private let contentCap: CGFloat = 380
    private let outerPad: CGFloat = 0

    // Vertical spacing
    private let topHeaderPad: CGFloat = 8
    private let headerToParticipants: CGFloat = 10
    private let participantsToLog: CGFloat = 12
    private let logToCards: CGFloat = 12
    private let cardsToAP: CGFloat = 12

    // Participants sizing
    private let participantGap: CGFloat = 12 // was 6; now larger gap between cards
    private let participantSideInset: CGFloat = 10 // squeeze row inside contentWidth for side/center air
    private let participantInnerPad: CGFloat = 0
    private let participantCardHeight: CGFloat = 284 // taller participant cards (try 240–260 if needed)

    // Log sizing
    private let logMinHeight: CGFloat = 110
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
                let participantW = max(0, (participantRowWidth - participantGap) / 2)

                VStack(spacing: 0) {
                    if let battle = store.battle {

                        // HEADER (debug left, floor centered, surrender right)
                        headerRow(floor: battle.floor)
                            .frame(width: contentWidth, alignment: .center)
                            .padding(.top, topHeaderPad)

                        Spacer().frame(height: headerToParticipants)

                        // PARTICIPANTS
                        HStack(spacing: participantGap) {
                            BattleParticipantCard(
                                title: "Player",
                                hp: battle.playerHP,
                                block: battle.playerBlock,
                                maxHP: 20,
                                intentText: nil
                            )
                            .frame(width: participantW)
                            .frame(height: participantCardHeight) // fixed participant card height
                            .padding(.horizontal, participantInnerPad)

                            BattleParticipantCard(
                                title: battle.enemyName,
                                hp: battle.enemyHP,
                                block: battle.enemyBlock,
                                maxHP: 20,
                                intentText: battle.enemyIntent.text
                            )
                            .frame(width: participantW)
                            .frame(height: participantCardHeight) // fixed participant card height
                            .padding(.horizontal, participantInnerPad)
                        }
                        .padding(.horizontal, participantSideInset) // side inset for the row
                        .frame(width: contentWidth, alignment: .center)

                        Spacer().frame(height: participantsToLog)

                        // LOG (main stretchy)
                        battleLogView
                            .frame(width: contentWidth, alignment: .center)
                            .frame(minHeight: logMinHeight)
                            .frame(maxHeight: max(0, geo.size.height - 64))
                            .layoutPriority(1)

                        Spacer().frame(height: logToCards)

                        // BOTTOM STACK: cards pinned to bottom area
                        bottomStack(contentWidth: contentWidth, battle: battle)
                            .frame(width: contentWidth, alignment: .center)
                            .layoutPriority(0)

                    } else {
                        VStack(spacing: 12) {
                            Text("No battle state")
                            Button("Back") { store.goToTower() }
                        }
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.top, 40)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .padding(.horizontal, outerPad)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Header

    private func headerRow(floor: Int) -> some View {
        ZStack {
            // Center title must stay centered on screen
            Text("Floor \(floor)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            // Left/Right controls
            HStack(alignment: .center) {
                // Top-left debug: win/lose (short)
                HStack(spacing: 8) {
                    Button("win") { store.winBattle() }
                        .font(.caption2)
                        .buttonStyle(.bordered)

                    Button("lose") { store.loseBattle() }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                }

                Spacer(minLength: 0)

                // Top-right surrender placeholder
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
                            // FIX: replace UIStyle.Color.cardStroke with safe color
                            Circle().stroke(Color.primary.opacity(0.18), lineWidth: 1)
                        )
                        .accessibilityLabel("Surrender")
                }
                .buttonStyle(.plain)
            }
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
                .padding(12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: logCorner))
                .overlay(
                    // FIX: replace UIStyle.Color.cardStroke with safe color
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

            // Cards row (visually glued to bottom block area)
            actionCardsRow(battle: battle)
                .frame(width: contentWidth, alignment: .center)

            Spacer().frame(height: cardsToAP)

            // AP label (RU, black, bold)
            Text("Очки действий: \(battle.actionPoints)")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer().frame(height: 10)

            // End Turn centered under AP
            Button("End Turn") { store.endTurn() }
                // FIX: remove dependency on battle.phase
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer().frame(height: 6)
        }
    }

    private func actionCardsRow(battle: BattleState) -> some View {
        // FIX: remove isEnemyPhase/phase usage
        return VStack(spacing: 8) {
            HStack(spacing: actionCardRowSpacing) {
                ForEach(battle.hand, id: \.id) { card in
                    // FIX: remove usedCardsThisTurn and phase checks; keep only AP
                    let hasAP = card.cost <= battle.actionPoints
                    let canPlay = hasAP

                    Button {
                        store.playCard(card)
                    } label: {
                        ActionCardView(card: card, disabled: !canPlay)
                            .frame(width: actionCardWidth, height: actionCardHeight)
                    }
                    .disabled(!canPlay)
                    .opacity(canPlay ? 1.0 : disabledOpacity)
                    .frame(width: actionCardWidth, height: actionCardHeight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Participant Card (square placeholder + tighter text)

private struct BattleParticipantCard: View {
    let title: String
    let hp: Int
    let block: Int
    let maxHP: Int
    let intentText: String? // nil for player

    private let cardCorner: CGFloat = 16
    private let innerPad: CGFloat = 10
    private let portraitInset: CGFloat = 8
    private let portraitCorner: CGFloat = 14

    // Participant card visual tokens (UI-KIT v1.x)
    private let participantBgOpacity: CGFloat = 0.55        // высокая прозрачность (виден фон)
    private let participantStrokeOpacity: CGFloat = 0.12    // мягкий контур
    private var participantBgTint: Color { Color(.systemGray5) } // сероватый, блеклый

    var body: some View {
        VStack(spacing: 6) {

            // Name (tighter)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.top, 2)

            // HP bar
            HPBar(value: hp, maxValue: maxHP)
                .frame(height: 6)
                .padding(.top, 2)

            // HP + Block (tighter)
            VStack(spacing: 2) {
                Text("HP: \(hp)/\(maxHP)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Block: \(block)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)

            // Intent (enemy) / reserved line (player) — tighter
            Group {
                if let intentText {
                    Text("Intent: \(intentText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else {
                    Text(" ")
                        .font(.caption2)
                }
            }
            .padding(.top, 2)

            Spacer(minLength: 0)

            // Portrait placeholder (elastic, pinned: L/R/B = 8)
            ZStack {
                RoundedRectangle(cornerRadius: portraitCorner)
                    .strokeBorder(.gray.opacity(0.20), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: portraitCorner)
                            .fill(.gray.opacity(0.08))
                    )

                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, portraitInset)
            .padding(.bottom, portraitInset)
            .aspectRatio(1, contentMode: .fit)
        }
        .padding(innerPad)
        .background(
            RoundedRectangle(cornerRadius: cardCorner)
                .fill(participantBgTint.opacity(participantBgOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner)
                .strokeBorder(.gray.opacity(participantStrokeOpacity), lineWidth: 1)
        )
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
