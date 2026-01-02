import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            if let battle = store.battle {
                VStack(spacing: 8) {
                    Text("Floor \(battle.floor)")
                        .font(.caption)

                    Text(battle.enemyName)
                        .font(.title2)

                    Text("Enemy HP: \(battle.enemyHP)")
                    Text("Player HP: \(battle.playerHP)")

                    // Enemy intent
                    HStack(spacing: 8) {
                        Text("Intent:")
                            .font(.caption)
                        Text("\(battle.enemyIntent.icon) \(battle.enemyIntent.text)")
                            .font(.caption)
                    }
                }

                // Combat Log
                VStack(alignment: .leading, spacing: 6) {
                    Text("Log")
                        .font(.caption)
                        .opacity(0.7)

                    ForEach(battle.log) { entry in
                        Text("• \(entry.text)")
                            .font(.caption2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

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
