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
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Win (debug)") {
                        store.winBattle()
                    }

                    Button("Lose (debug)") {
                        store.loseBattle()
                    }

                    Button("Surrender") {
                        store.surrenderBattle()
                    }
                }
            } else {
                Text("No battle state")
                Button("Back") { store.goToTower() }
            }
        }
        .padding()
    }
}
