struct TowerService {
    
    // MARK: - Room Descriptions
    
    private let combatDescriptions = [
        "Обычные враги охраняют путь.",
        "Впереди слышен звон оружия.",
        "Тени движутся в темноте.",
        "Стражи башни ждут тебя."
    ]
    
    private let eliteDescriptions = [
        "Могущественный противник преграждает путь.",
        "Элитный страж не отступит без боя.",
        "Опасный враг с особыми способностями."
    ]
    
    private let bossDescriptions = [
        "Хозяин этажа ждёт финальной схватки.",
        "Босс акта готов к бою.",
        "Решающее сражение впереди."
    ]
    
    private let eventDescriptions = [
        "Странная встреча ждёт тебя.",
        "Таинственный незнакомец предлагает выбор.",
        "Судьба готовит испытание."
    ]
    
    private let restDescriptions = [
        "Безопасное место для отдыха.",
        "Костёр даёт передышку.",
        "Восстанови силы перед следующим боем."
    ]
    
    private let chestDescriptions = [
        "Древний сундук с сокровищами.",
        "Награда за храбрость.",
        "Артефакт ждёт своего владельца."
    ]
    
    // MARK: - Generation
    
    func generateRoomOptions(run: RunState) -> [RoomOption] {
        // Boss floor: single mandatory option
        if run.isBossFloor {
            return [makeBossRoom(actIndex: run.actIndex)]
        }

        // Pre-boss floor: guarantee Rest among the 3 options
        if run.floorInAct == RunState.floorsPerAct {
            var options: [RoomOption] = [
                makeCombatRoom(),
                makeCombatRoom(),
                makeRestRoom()
            ]
            options.shuffle()
            return options
        }

        // Base: two combats + one "special"
        var optionA = makeCombatRoom()
        var optionB = makeCombatRoom()

        // Sprinkle elites in mid/late act by upgrading one combat slot.
        if run.floorInAct >= 5, run.floorInAct % 2 == 1 {
            optionB = makeEliteRoom()
        }

        // Special slot: event early, event/chest later (chest can be locked)
        let chestLocked = (run.nonCombatStreak >= 2)
        let special: RoomOption = {
            if run.floorInAct <= 2 {
                return makeEventRoom()
            }
            let pool: [RoomKind] = [.event, .chest, .chest]
            let picked = pool.randomElement() ?? .event
            if picked == .chest {
                return makeChestRoom(isLocked: chestLocked)
            }
            return makeEventRoom()
        }()

        var options: [RoomOption] = [optionA, optionB, special]
        options.shuffle()
        return options
    }
    
    // MARK: - Room Factories
    
    private func makeCombatRoom() -> RoomOption {
        let enemy = RuntimeEnemyKind.allCases.randomElement() ?? .punisher
        let desc = combatDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .combat,
            isLocked: false,
            difficulty: 1,
            descriptionText: desc,
            previewEnemy: enemy
        )
    }
    
    private func makeEliteRoom() -> RoomOption {
        let enemy = RuntimeEnemyKind.allCases.randomElement() ?? .graphiteGolem
        let desc = eliteDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .elite,
            isLocked: false,
            difficulty: 2,
            descriptionText: desc,
            previewEnemy: enemy
        )
    }
    
    private func makeBossRoom(actIndex: Int) -> RoomOption {
        // Boss depends on act
        let bossEnemy: RuntimeEnemyKind = {
            switch actIndex {
            case 1: return .punisher
            case 2: return .zesurumiMonks
            default: return .feyanchа
            }
        }()
        let desc = bossDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .boss,
            isLocked: false,
            difficulty: 3,
            descriptionText: desc,
            previewEnemy: bossEnemy
        )
    }
    
    private func makeEventRoom() -> RoomOption {
        let desc = eventDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .event,
            isLocked: false,
            difficulty: 0,
            descriptionText: desc,
            previewEnemy: nil
        )
    }
    
    private func makeRestRoom() -> RoomOption {
        let desc = restDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .rest,
            isLocked: false,
            difficulty: 0,
            descriptionText: desc,
            previewEnemy: nil
        )
    }
    
    private func makeChestRoom(isLocked: Bool) -> RoomOption {
        let desc = chestDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .chest,
            isLocked: isLocked,
            difficulty: 0,
            descriptionText: desc,
            previewEnemy: nil
        )
    }
}
