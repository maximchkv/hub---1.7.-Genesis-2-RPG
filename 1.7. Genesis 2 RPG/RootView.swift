import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        NavigationStack {
            if store.run == nil {
                StartView()
            } else {
                HubView()
            }
        }
    }
}
