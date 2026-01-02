import SwiftUI

struct ChestView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Chest")
                .font(.title)

            Text("🧰")
                .font(.system(size: 64))

            if let chest = store.chest {
                if chest.isOpened, let art = chest.revealed {
                    // Result
                    VStack(spacing: 8) {
                        Text("\(art.icon) \(art.name)")
                            .font(.headline)
                        Text(art.description)
                            .font(.caption)
                        Text("Income bonus: +\(art.incomeBonus)/day")
                            .font(.caption2)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button("Send to Castle & Continue") {
                        store.claimChestRewardAndContinue()
                    }
                } else {
                    // Open
                    Button("Open Chest") {
                        store.openChest()
                    }
                }
            } else {
                Text("No chest state (stub)")
                    .font(.caption)
                Button("Back to Tower") {
                    store.goToTower()
                }
            }
        }
        .padding()
    }
}
