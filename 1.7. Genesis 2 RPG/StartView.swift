import SwiftUI

struct StartView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Start")
                .font(.title)

            Button("Start Run (debug)") {
                store.run = RunState(currentFloor: 1)
            }
        }
        .padding()
    }
}
