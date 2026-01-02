import SwiftUI
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published var meta: PlayerMeta
    @Published var run: RunState? = nil
    @Published var route: Route = .start
    @Published var toast: String? = nil

    private let towerService = TowerService()

    init(meta: PlayerMeta = PlayerMeta()) {
        self.meta = meta
    }

    // MARK: - Navigation
    func goToStart() { route = .start }
    func goToHub() { route = .hub }
    func goToTower() { route = .tower }
    func goToCastle() { route = .castle }
    func goToCardLibrary() { route = .cardLibrary }

    // MARK: - Run
    func startRun() {
        var newRun = RunState(currentFloor: 1)
        newRun.roomOptions = towerService.generateRoomOptions(nonCombatStreak: newRun.nonCombatStreak)
        run = newRun
        route = .hub
    }

    func endRun() {
        run = nil
        route = .start
    }

    // MARK: - Tower
    func refreshRoomOptions() {
        guard var run else { return }
        run.roomOptions = towerService.generateRoomOptions(nonCombatStreak: run.nonCombatStreak)
        self.run = run
    }

    func selectRoom(_ option: RoomOption) {
        guard var run else { return }
        if option.kind == .chest && option.isLocked {
            // locked: игнорируем выбор
            return
        }

        switch option.kind {
        case .combat:
            run.nonCombatStreak = 0
        case .chest:
            run.nonCombatStreak += 1
        }

        // имитация "продвинулся на этаж"
        run.currentFloor += 1

        // Day tick — РОВНО один раз на выбор комнаты
        applyDayTick()

        // обновить bestFloor
        meta.bestFloor = max(meta.bestFloor, run.currentFloor)

        // сгенерить новые варианты
        run.roomOptions = towerService.generateRoomOptions(nonCombatStreak: run.nonCombatStreak)

        self.run = run
        route = .tower
    }

    // DEBUG: имитация "день прошёл"
    func debugDayTick() {
        meta.days += 1
        meta.gold += 3
        if let run {
            meta.bestFloor = max(meta.bestFloor, run.currentFloor)
        }
    }

    // MARK: - Day Tick
    func applyDayTick() {
        meta.days += 1
        meta.gold += meta.incomePerDay
        toast = "Day +1  •  Gold +\(meta.incomePerDay)"
    }
}
