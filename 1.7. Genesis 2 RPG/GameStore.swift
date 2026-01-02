import SwiftUI
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published var run: RunState? = nil

    init() {}
}
