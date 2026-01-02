import SwiftUI

struct TowerView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Tower (stub)")
                .font(.title)

            Button("Back to Hub") {
                store.goToHub()
            }
        }
        .padding()
    }
}
