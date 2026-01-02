struct RunState {
    var currentFloor: Int
    var nonCombatStreak: Int
    var roomOptions: [RoomOption]

    init(currentFloor: Int = 1) {
        self.currentFloor = currentFloor
        self.nonCombatStreak = 0
        self.roomOptions = []
    }
}
