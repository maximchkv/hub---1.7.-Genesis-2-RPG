import SwiftUI

struct HubView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            // Meta header
            VStack(spacing: 8) {
                HStack {
                    Text("Days: \(store.meta.days)")
                    Spacer()
                    Text("Gold: \(store.meta.gold)")
                    Spacer()
                    Text("Best: \(store.meta.bestFloor)")
                }
                .font(.headline)

                if let run = store.run {
                    Text("Current Floor: \(run.currentFloor)")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Debug actions
            Button("Day Tick (debug)") {
                store.debugDayTick()
            }

            Button("End Run (debug)") {
                store.endRun()
            }
        }
        .padding()
    }
}
