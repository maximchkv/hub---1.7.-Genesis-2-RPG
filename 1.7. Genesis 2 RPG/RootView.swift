import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        NavigationStack {
            switch store.route {
            case .start:
                StartView()
            case .hub:
                HubView()
            case .tower:
                TowerView()
            case .castle:
                CastleView()
            case .cardLibrary:
                CardLibraryView()
            }
        }
    }
}
