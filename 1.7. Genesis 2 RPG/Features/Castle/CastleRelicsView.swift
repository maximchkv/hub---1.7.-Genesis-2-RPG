import SwiftUI

struct CastleRelicsView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Relics")
                .font(.title)

            Text("Relic system coming soon")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Back") {
                store.backToCastleMain()
            }

            Spacer()
        }
        .padding()
    }
}
