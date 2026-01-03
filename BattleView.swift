// GPT_EDIT_TEST_001
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    // Spacing/layout constants for 019C3
    private let topHeaderPad: CGFloat = 10
    private let gapHeaderToPanels: CGFloat = 10
    private let gapPanelsToLog: CGFloat = 12
    private let panelsHeight: CGFloat = 92

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 12) {
                if let battle = store.battle {
                    // 1) Header (Floor) with fixed top padding
                    Text("Floor \(battle.floor)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, topHeaderPad)

                    // 2) Player/Enemy panels (fixed height + explicit top gap)
                    playerEnemyPanels
                        .frame(height: panelsHeight)
                        .padding(.top, gapHeaderToPanels)
                        .padding(.horizontal, 16)

                    // 3) Logs: start below panels with explicit top gap, take remaining space
                    battleLogView
                        .padding(.top, gapPanelsToLog)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 16)

                    // 4) Actions row (fixed)
                    actionsRow
                        .padding(.horizontal, 16)

                    // 5) Bottom buttons (fixed, 2 rows)
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

    // MARK: - Sections

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
                // Important: do not add negative offsets/overlays here
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
                    let cardHeight: CGFloat = 180
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
            .layoutPriority(1) // text column has priority over avatar when space is tight

            // Player avatar placeholder is on the RIGHT
            if side == .player {
                avatarPlaceholder
            }
        }
        .padding(12)
        .frame(height: 120) // keeps internal layout consistent; outer container clamps to panelsHeight
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

    // Reserve a consistent Intent row in both panels; enemy shows content, player shows empty row
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
                // Reserve same vertical space in Player panel
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
        }
    }

    private func intentSymbol(_ k: EnemyIntentKind) -> String {
        switch k {
        case .attack: return "sword"
        case .defend: return "shield"
        case .counter: return "arrow.triangle.2.circlepath"
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
