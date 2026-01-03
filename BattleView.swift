// GPT_EDIT_TEST_001
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            if let battle = store.battle {

                // T3-ARCH-BOOT-019A — Header + Status Area (scaffold)
                VStack(spacing: 10) {

                    // Header (Floor)
                    Text("Floor \(battle.floor)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Status Area (2 equal panels)
                    HStack(spacing: 12) {

                        StatusPanel(
                            side: .player,
                            name: "Player",
                            hp: battle.playerHP,
                            maxHP: 20,
                            block: battle.playerBlock,
                            intentKind: nil
                        )

                        StatusPanel(
                            side: .enemy,
                            name: battle.enemyName,
                            hp: battle.enemyHP,
                            maxHP: 20,
                            block: battle.enemyBlock,
                            intentKind: battle.enemyIntent.kind
                        )
                    }
                }

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
                .frame(maxHeight: .infinity, alignment: .top)

                // Bottom controls
                VStack(spacing: 8) {
                    Text("Action Points: \(battle.actionPoints)")
                        .font(.caption)

                    // Layout constants
                    let cardWidth: CGFloat = 96
                    let rowSpacing: CGFloat = 16
                    let sideInset: CGFloat = 16

                    let count = battle.hand.count
                    let totalWidth =
                        CGFloat(count) * cardWidth +
                        CGFloat(max(0, count - 1)) * rowSpacing

                    let isEnemyPhase = (battle.phase == .enemy)

                    HStack {
                        Spacer(minLength: 0)

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
                                    .frame(width: cardWidth)
                                }
                                .disabled(!canPlay)
                                .opacity(canPlay ? 1 : 0.35)
                                .frame(width: cardWidth)
                            }
                        }
                        .frame(width: totalWidth, alignment: .center)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, sideInset)
                    .frame(height: 120)

                    HStack(spacing: 16) {
                        Button("End Turn") {
                            store.endTurn()
                        }
                        .disabled(isEnemyPhase)

                        Button("Surrender") {
                            store.surrenderBattle()
                        }
                    }

                    // Debug/flow controls
                    VStack(spacing: 12) {
                        Button("Win (debug)") { store.winBattle() }
                        Button("Lose (debug)") { store.loseBattle() }
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("No battle state")
                Button("Back") { store.goToTower() }
            }
        }
        .padding()
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

                VStack(alignment: .leading, spacing: 6) {
                    Text("HP: \(hp) / \(maxHP)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HPBar(value: hp, maxValue: maxHP)
                        .frame(height: 6)
                }

                Text("Block: \(block)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
        .frame(height: 120) // fixed panel height so it never jumps
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
                    .lineLimit(2)                 // allow long text
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)     // soft fallback if too long
            } else {
                // Reserve same vertical space in Player panel
                Text(" ")
                    .font(.caption)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.secondary)
        .frame(minHeight: 28, alignment: .topLeading) // keeps panels stable
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
