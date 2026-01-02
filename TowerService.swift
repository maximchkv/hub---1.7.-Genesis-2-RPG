struct TowerService {
    func generateRoomOptions(nonCombatStreak: Int) -> [RoomOption] {
        // MVP: всегда 2 боя + 1 сундук
        // правило: если уже 2 сундука подряд, то сундук блокируется
        let chestLocked = (nonCombatStreak >= 2)

        var options: [RoomOption] = [
            RoomOption(kind: .combat),
            RoomOption(kind: .combat),
            RoomOption(kind: .chest, isLocked: chestLocked)
        ]

        // перемешаем порядок, чтобы не всегда сундук был третьим
        options.shuffle()
        return options
    }
}
