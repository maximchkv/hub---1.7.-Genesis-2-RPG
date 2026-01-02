import SwiftUI
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published var meta: PlayerMeta
    @Published var run: RunState? = nil

    init(meta: PlayerMeta = PlayerMeta()) {
        self.meta = meta
    }

    // DEBUG: старт/конец забега
    func startRun() {
        run = RunState(currentFloor: 1)
    }

    func endRun() {
        run = nil
    }

    // DEBUG: имитация "день прошёл"
    func debugDayTick() {
        meta.days += 1
        meta.gold += 3
        if let run {
            meta.bestFloor = max(meta.bestFloor, run.currentFloor)
        }
    }
}
