import SwiftUI

struct RestView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Rest")
                .font(.largeTitle)

            Text("A short pause before the climb continues.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("🔥")
                .font(.system(size: 64))

            Button("Continue") {
                store.completeNonCombatRoomAndContinue(kind: .rest)
            }
        }
        .padding()
    }
}

