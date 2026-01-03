import SwiftUI

struct CastleView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack {
            switch store.castleRoute {
            case .main:
                castleMain
            case .upgrade:
                CastleUpgradeView()
            case .relics:
                CastleRelicsView()
            }
        }
    }

    private var castleMain: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Castle")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Safe zone")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 12) {
                Button("Upgrade") {
                    store.goToCastleUpgrade()
                }
                .buttonStyle(.borderedProminent)

                Button("Relics") {
                    store.goToCastleRelics()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button("Back to Hub") {
                store.goToHub()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }
}
