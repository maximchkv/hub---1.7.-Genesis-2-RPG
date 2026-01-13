import SwiftUI

struct VictoryView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Victory")
                .font(.largeTitle)

            Text("You cleared all 3 acts.")
                .foregroundStyle(.secondary)

            Text("👑")
                .font(.system(size: 72))

            VStack(spacing: 6) {
                Text("Best floor: \(store.meta.bestFloor)")
                    .font(.caption)
                Text("Days: \(store.meta.days)")
                    .font(.caption)
                Text("Gold: \(store.meta.gold)")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Button("Return to Hub") {
                store.finishRunAndReturnToHub()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

