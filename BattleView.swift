// GPT_EDIT_TEST_001
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            if let battle = store.battle {
                VStack(spacing: 8) {
                    // тетаоашмтоако
                    Text("Floor \(battle.floor)")
                        .font(.caption)

                    Text(battle.enemyName)
                        .font(.title2)

                    // HP + Block
                    Text("Enemy HP: \(battle.enemyHP)    Block: \(battle.enemyBlock)")
                    Text("Player HP: \(battle.playerHP)    Block: \(battle.playerBlock)")

                    // Enemy intent
                    HStack(spacing: 8) {
                        Text("Intent:")
                            .font(.caption)
                        Text("\(battle.enemyIntent.icon) \(battle.enemyIntent.text)")
                            .font(.caption)
                    }
                }

                // --- Log (scrollable, keeps full history) ---
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(battle.log.enumerated()), id: \.offset) { _, entry in
                            if entry.text == "__DIVIDER__" {
                                Divider()
                                    .padding(.vertical, 6)
                            } else {
                                Text(entry.text)
                                    .font(.caption2)
                                    .fontWeight(entry.isPlayer ? .bold : .regular)
                                    .foregroundStyle(entry.isPlayer ? .primary : .secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .top)

                // Bottom controls (cards centered)
                VStack(spacing: 8) {
                    Text("Action Points: \(battle.actionPoints)")
                        .font(.caption)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Spacer(minLength: 0)

                            HStack(spacing: 12) {
                                ForEach(battle.hand) { card in
                                    Button {
                                        store.playCard(card)
                                    } label: {
                                        ActionCardView(
                                            card: card,
                                            disabled: battle.actionPoints < card.cost
                                        )
                                    }
                                    .disabled(battle.actionPoints < card.cost)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    }

                    HStack(spacing: 16) {
                        Button("End Turn") {
                            store.endTurn()
                        }
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
