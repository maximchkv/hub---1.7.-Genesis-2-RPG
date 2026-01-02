import SwiftUI

struct CardLibraryView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Card Library (stub)")
                .font(.title)

            Button("Back to Hub") {
                store.goToHub()
            }
        }
        .padding()
    }
}
