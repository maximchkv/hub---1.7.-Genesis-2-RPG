import SwiftUI

struct CastleView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Castle (stub)")
                .font(.title)

            Button("Back to Hub") {
                store.goToHub()
            }
        }
        .padding()
    }
}
