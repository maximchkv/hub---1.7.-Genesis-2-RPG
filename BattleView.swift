// GPT_EDIT_TEST_001
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    // MARK: - Layout constants (Contract v1.1)
    private let topHeaderPad: CGFloat = 10

    // Fixed vertical gaps
    private let headerToParticipants: CGFloat = 24
    private let participantsToLog: CGFloat = 24
    private let logToActionPoints: CGFloat = 12
    private let actionsToButtons: CGFloat = 120

    // Participants sizing
    private let participantMinHeight: CGFloat = 200
    private let participantMaxHeight: CGFloat = 400

    // Log sizing (bounded, because we now allow vertical scroll)
    private let logMinHeight: CGFloat = 120
    private let logMaxHeight: CGFloat = 260

    var body: some View {
        ZStack {
            UIStyle.background()
                .ignoresSafeArea()

            GeometryReader { geo in
                let outerPad: CGFloat = 16
                let available = max(0, geo.size.width - outerPad * 2)
                let contentWidth = min(available, 380)

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        if let battle = store.battle {

                            // Header
                            Text("Floor \(battle.floor)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, topHeaderPad)
                                .frame(width: contentWidth, alignment: .center)

                            VGap(h: headerToParticipants)

                            // Participants — fixed width split to avoid horizontal drift
                            let participantGap: CGFloat = 12
                            let participantW = max(0, (contentWidth - participantGap) / 2)

                            HStack(spacing: participantGap) {
                                BattleParticipantCard(
                                    title: "Player",
                                    hp: battle.playerHP,
                                    block: battle.playerBlock,
                                    maxHP: 20,
                                    intentText: nil,
                                    isEnemy: false
                                )
                                .frame(width: participantW)
                                .frame(minHeight: participantMinHeight)
                                .frame(maxHeight: participantMaxHeight)

                                BattleParticipantCard(
                                    title: battle.enemyName,
                                    hp: battle.enemyHP,
                                    block: battle.enemyBlock,
                                    maxHP: 20,
                                    intentText: battle.enemyIntent.text,
                                    isEnemy: true
                                )
                                .frame(width: participantW)
                                .frame(minHeight: participantMinHeight)
                                .frame(maxHeight: participantMaxHeight)
                            }
                            .frame(width: contentWidth, alignment: .center)

                            VGap(h: participantsToLog)

                            // Log — bounded height + full width
                            battleLogView
                                .frame(width: contentWidth, alignment: .center)
                                .frame(minHeight: logMinHeight)
                                .frame(maxHeight: logMaxHeight)

                            Spacer().frame(height: logToActionPoints)

                            // Actions — responsive card width (fixes horizontal overflow)
                            actionsRow(contentWidth: contentWidth)
                                .frame(width: contentWidth, alignment: .center)

                            Spacer().frame(height: actionsToButtons)

                            // Bottom buttons — full width
                            bottomButtons
                                .frame(width: contentWidth, alignment: .center)
                                .padding(.bottom, 10)

                        } else {
                            VStack(spacing: 12) {
                                Text("No battle state")
                                Button("Back") { store.goToTower() }
                            }
                            .frame(width: contentWidth, alignment: .center)
                            .padding(.top, 24)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, outerPad)
                    .padding(.vertical, 0)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: - Sections

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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity)
            } else {
                EmptyView()
            }
        }
    }

    private func actionsRow(contentWidth: CGFloat) -> some View {
        Group {
            if let battle = store.battle {
                VStack(spacing: 8) {
                    Text("Action Points: \(battle.actionPoints)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    let rowSpacing: CGFloat = 12
                    let count = max(1, min(3, battle.hand.count))

                    let maxCardW: CGFloat = 120
                    let cardW = min(maxCardW, (contentWidth - rowSpacing * CGFloat(count - 1)) / CGFloat(count))
                    let cardH = min(170, max(140, cardW * 1.42))

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
                                .frame(width: cardW, height: cardH)
                            }
                            .disabled(!canPlay)
                            .opacity(canPlay ? 1 : 0.35)
                            .frame(width: cardW, height: cardH)
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
                    HStack(spacing: 12) {
                        Button("End Turn") { store.endTurn() }
                            .disabled(isEnemyPhase)
                            .frame(maxWidth: .infinity)

                        Button("Surrender") { store.surrenderBattle() }
                            .frame(maxWidth: .infinity)
                    }

                    HStack(spacing: 12) {
                        Button("win_debug") { store.winBattle() }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)

                        Button("lose_debug") { store.loseBattle() }
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

// MARK: - Hard vertical gap mini-component
private struct VGap: View {
    let h: CGFloat
    var body: some View {
        Color.clear
            .frame(height: h)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(10)
    }
}

// MARK: - New big participant card for top area
private struct BattleParticipantCard: View {
    let title: String
    let hp: Int
    let block: Int
    let maxHP: Int

    let intentText: String?
    let isEnemy: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 44)

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
            .frame(height: 120)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.gray.opacity(0.18), lineWidth: 1)
        )
    }
}
