import SwiftUI

struct CastleUpgradeView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Upgrade")
                .font(.title)

            Text("Upgrade system coming soon")
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
