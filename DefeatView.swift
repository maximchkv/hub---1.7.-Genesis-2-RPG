import SwiftUI

struct DefeatView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Defeat")
                .font(.largeTitle)

            Text("The run has ended.")

            Button("Return to Hub") {
                store.resetRun()
            }
        }
        .padding()
    }
}
