struct TowerService {
    func generateRoomOptions(run: RunState) -> [RoomOption] {
        // Boss floor: single mandatory option
        if run.isBossFloor {
            return [RoomOption(kind: .boss)]
        }

        // Pre-boss floor: guarantee Rest among the 3 options
        if run.floorInAct == RunState.floorsPerAct {
            var options: [RoomOption] = [
                RoomOption(kind: .combat),
                RoomOption(kind: .combat),
                RoomOption(kind: .rest)
            ]
            options.shuffle()
            return options
        }

        // Base: two combats + one "special"
        var optionA = RoomOption(kind: .combat)
        var optionB = RoomOption(kind: .combat)

        // Sprinkle elites in mid/late act by upgrading one combat slot.
        if run.floorInAct >= 5, run.floorInAct % 2 == 1 {
            // Make one of the combats elite (still a combat for streak purposes)
            optionB = RoomOption(kind: .elite)
        }

        // Special slot: event early, event/chest later (chest can be locked)
        let chestLocked = (run.nonCombatStreak >= 2)
        let special: RoomOption = {
            if run.floorInAct <= 2 {
                return RoomOption(kind: .event)
            }
            // Weighted-ish: chest more common after early floors
            let pool: [RoomKind] = [.event, .chest, .chest]
            let picked = pool.randomElement() ?? .event
            if picked == .chest {
                return RoomOption(kind: .chest, isLocked: chestLocked)
            }
            return RoomOption(kind: picked)
        }()

        var options: [RoomOption] = [optionA, optionB, special]
        options.shuffle()
        return options
    }
}
