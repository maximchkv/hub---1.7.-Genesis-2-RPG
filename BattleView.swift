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
                        ForEach(battle.log) { entry in
                            if entry.kind == .separator {
                                Divider()
                            } else {
                                Text(entry.text)
                                    .font(.caption2)
                                    .fontWeight(entry.isPlayer ? .bold : .regular)
                                    .foregroundStyle(entry.kind == .system ? .secondary : .primary)
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

                // Bottom controls (no Spacer above, so log can expand)
                VStack(spacing: 8) {
                    Text("Action Points: \(battle.actionPoints)")
                        .font(.caption)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(battle.hand) { card in
                                ActionCardView(
                                    card: card,
                                    disabled: battle.actionPoints < card.cost
                                )
                                .onTapGesture {
                                    store.playCard(card)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Button("End Turn") {
                        store.endTurn()
                    }

                    // Debug/flow controls
                    VStack(spacing: 12) {
                        Button("Win (debug)") { store.winBattle() }
                        Button("Lose (debug)") { store.loseBattle() }
                        Button("Surrender") { store.surrenderBattle() }
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
