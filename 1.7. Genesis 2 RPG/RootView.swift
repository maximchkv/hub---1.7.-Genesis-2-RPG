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
            case .chest:
                ChestView()
            case .battle:
                BattleView()
            case .defeat:
                DefeatView()
            case .rest:
                RestView()
            case .event:
                EventView()
            case .reward:
                RewardView()
            case .victory:
                VictoryView()
            case .castle:
                CastleView()
            case .cardLibrary:
                CardLibraryView()
            }
        }
    }
}
