// GPT_EDIT_TEST_001
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    // MARK: - Layout constants (027C-E/F)
    private let topHeaderPad: CGFloat = 10

    // Required spacings (single-source gaps)
    private let headerToParticipants: CGFloat = 32
    private let participantsToLog: CGFloat = 32   // ВИДИМЫЙ зазор между Participants и Log
    private let logToActionPoints: CGFloat = 12
    private let actionsToButtons: CGFloat = 12

    // Participant cards: растягиваем в первую очередь (уменьшаем “пустоту” по центру)
    private let participantCardHeight: CGFloat = 240

    // Log: compact baseline; now expands to fill remaining height
    private let logHeight: CGFloat = 104 // 120 - 16, освобождаем место под зазор

    // No longer used for outer height bumps per 027C v3
    private let participantExtraHeight: CGFloat = 0

    var body: some View {
        ZStack {
            UIStyle.background
                .ignoresSafeArea()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    if let battle = store.battle {

                        Text("Floor \(battle.floor)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, topHeaderPad)

                        // жёсткий gap: Header → Participants (единственный источник отступа)
                        Spacer()
                            .frame(height: headerToParticipants)

                        // Participants
                        HStack(spacing: 12) {
                            BattleParticipantCard(
                                title: "Player",
                                hp: battle.playerHP,
                                block: battle.playerBlock,
                                maxHP: 20,
                                intentText: nil,
                                isEnemy: false
                            )
                            .frame(height: participantCardHeight)

                            BattleParticipantCard(
                                title: battle.enemyName,
                                hp: battle.enemyHP,
                                block: battle.enemyBlock,
                                maxHP: 20,
                                intentText: battle.enemyIntent.text,
                                isEnemy: true
                            )
                            .frame(height: participantCardHeight)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 0)

                        // ЖЁСТКИЙ зазор между Participants и Log (не через padding, а через Spacer)
                        Spacer()
                            .frame(height: participantsToLog)

                        // Log: eats remaining height to keep bottom anchored and gaps fixed
                        battleLogView
                            .frame(minHeight: logHeight)
                            .frame(maxHeight: .infinity)
                            .padding(.horizontal, 16)
                            .layoutPriority(1)

                        // Fixed gap to Action Points
                        Spacer()
                            .frame(height: logToActionPoints)

                        actionsRow
                            .padding(.horizontal, 16)

                        Spacer()
                            .frame(height: actionsToButtons)

                        bottomButtons
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)

                    } else {
                        Text("No battle state")
                        Button("Back") { store.goToTower() }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
            .padding(.vertical, 0)
        }
    }

    // MARK: - Sections

    // Legacy panels replaced by new big cards, but we leave these helpers in case other views rely on them.
    private var playerEnemyPanels: some View {
        HStack(spacing: 12) {
            playerPanel
                .frame(maxWidth: .infinity)

            enemyPanel
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private var playerPanel: some View {
        Group {
            if let b = store.battle {
                StatusPanel(
                    side: .player,
                    name: "Player",
                    hp: b.playerHP,
                    maxHP: 20,
                    block: b.playerBlock,
                    intentKind: nil
                )
            } else {
                EmptyView()
            }
        }
    }

    private var enemyPanel: some View {
        Group {
            if let b = store.battle {
                StatusPanel(
                    side: .enemy,
                    name: b.enemyName,
                    hp: b.enemyHP,
                    maxHP: 20,
                    block: b.enemyBlock,
                    intentKind: b.enemyIntent.kind
                )
            } else {
                EmptyView()
            }
        }
    }

    private var battleLogView: some View {
        Group {
            if let battle = store.battle {
                // --- Log (auto-scroll to bottom) ---
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

                            // bottom anchor (stable id)
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity)
            } else {
                EmptyView()
            }
        }
    }

    private var actionsRow: some View {
        Group {
            if let battle = store.battle {
                VStack(spacing: 8) {
                    Text("Action Points: \(battle.actionPoints)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    // Layout constants (kept contained)
                    let cardWidth: CGFloat = 120
                    let cardHeight: CGFloat = 170
                    let rowSpacing: CGFloat = 12

                    let isEnemyPhase = (battle.phase == .enemy)

                    HStack(spacing: rowSpacing) {
                        ForEach(battle.hand, id: \.id) { card in
                            let isUsed = battle.usedCardsThisTurn.contains(card.kind)
                            let hasAP = card.cost <= battle.actionPoints
                            let canPlay = !isEnemyPhase && hasAP && !isUsed

                            Button {
                                store.playCard(card)
                            } label: {
                                ActionCardView(
                                    card: card,
                                    disabled: !canPlay
                                )
                                .frame(width: cardWidth, height: cardHeight)
                            }
                            .disabled(!canPlay)
                            .opacity(canPlay ? 1 : 0.35)
                            .frame(width: cardWidth, height: cardHeight)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                EmptyView()
            }
        }
    }

    private var bottomButtons: some View {
        Group {
            if let battle = store.battle {
                let isEnemyPhase = (battle.phase == .enemy)

                VStack(spacing: 8) {
                    // Row 1: End Turn / Surrender
                    HStack(spacing: 12) {
                        Button("End Turn") { store.endTurn() }
                            .disabled(isEnemyPhase)
                            .frame(maxWidth: .infinity)

                        Button("Surrender") { store.surrenderBattle() }
                            .frame(maxWidth: .infinity)
                    }

                    // Row 2: win_debug / lose_debug
                    HStack(spacing: 12) {
                        Button("win_debug") {
                            store.winBattle()
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)

                        Button("lose_debug") {
                            store.loseBattle()
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
}

// T3-ARCH-BOOT-019A — Status Area building blocks

private enum StatusSide {
    case player
    case enemy
}

private struct StatusPanel: View {
    let side: StatusSide
    let name: String
    let hp: Int
    let maxHP: Int
    let block: Int
    let intentKind: EnemyIntentKind?

    var body: some View {
        HStack(spacing: 12) {

            // Enemy avatar placeholder is on the LEFT
            if side == .enemy {
                avatarPlaceholder
            }

            VStack(alignment: .leading, spacing: 8) {

                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                VStack(alignment: .leading, spacing: 6) {
                    Text("HP: \(hp) / \(maxHP)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    HPBar(value: hp, maxValue: maxHP)
                        .frame(height: 6)
                }

                Text("Block: \(block)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                // Fixed Intent row (reserved space in both panels to prevent jumping)
                intentRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            // Player avatar placeholder is on the RIGHT
            if side == .player {
                avatarPlaceholder
            }
        }
        .padding(12)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var avatarPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color(.tertiaryLabel), lineWidth: 1)
            .frame(width: 54, height: 54)
            .overlay(
                Image(systemName: "person.crop.square")
                    .foregroundStyle(.tertiary)
            )
            .accessibilityLabel("Avatar placeholder")
    }

    private var intentRow: some View {
        HStack(spacing: 6) {
            if side == .enemy, let k = intentKind {
                Image(systemName: intentSymbol(k))
                    .font(.caption)

                Text("Intent: \(intentTitle(k))")
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)
            } else {
                Text(" ")
                    .font(.caption)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.secondary)
        .frame(minHeight: 28, alignment: .topLeading)
    }

    private func intentTitle(_ k: EnemyIntentKind) -> String {
        switch k {
        case .attack: return "Attack"
        case .defend: return "Defend"
        case .counter: return "Counter"
        case .counterStance: return "Counter Stance"
        case .doubleStrikeFixed4: return "Double Strike"
        }
    }

    private func intentSymbol(_ k: EnemyIntentKind) -> String {
        switch k {
        case .attack: return "sword"
        case .defend: return "shield"
        case .counter: return "arrow.triangle.2.circlepath"
        case .counterStance: return "arrow.triangle.2.circlepath"
        case .doubleStrikeFixed4: return "suit.heart"
        }
    }
}

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
                    .fill(Color(.systemGreen))
                    .frame(width: fillW)
            }
        }
        .frame(height: 6)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - New big participant card for top area
private struct BattleParticipantCard: View {
    let title: String
    let hp: Int
    let block: Int
    let maxHP: Int

    let intentText: String?          // nil for player
    let isEnemy: Bool

    var body: some View {
        VStack(spacing: 10) {
            // 1) Name (reserve space for 2 lines to avoid height jumps)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 44) // резерв под 2 строки, стабилизирует высоту

            // 2) HP bar + numbers + block
            VStack(spacing: 6) {
                ProgressView(value: Double(hp), total: Double(maxHP))
                    .frame(maxWidth: .infinity)

                Text("HP: \(hp)/\(maxHP)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Block: \(block)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // 3) Intent row (enemy) / empty row (player)
            Group {
                if let intentText {
                    Text("Intent: \(intentText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text(" ")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            // 4) Big image placeholder (+10 participates in the card bump)
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.gray.opacity(0.25), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.gray.opacity(0.08))
                    )

                Image(systemName: "photo")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120) // compact; if previous was 110, this is +10
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground)) // непрозрачно, убирает “просвет”
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.gray.opacity(0.18), lineWidth: 1)
        )
    }
}
