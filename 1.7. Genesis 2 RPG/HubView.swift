import SwiftUI

struct HubView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Hub")
                .font(.title)

            Text("Floor: \(store.run?.currentFloor ?? 0)")

            Button("End Run (debug)") {
                store.run = nil
            }
        }
        .padding()
    }
}
