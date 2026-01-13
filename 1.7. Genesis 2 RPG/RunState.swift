struct RunState {
    // MARK: - Run structure (Acts v1)
    static let actCount: Int = 3
    static let floorsPerAct: Int = 10 // normal floors before boss

    /// 1...actCount
    var actIndex: Int

    /// 1...floorsPerAct for normal floors, floorsPerAct+1 for boss floor
    var floorInAct: Int

    var nonCombatStreak: Int
    var roomOptions: [RoomOption]

    /// Becomes `true` after the 3rd boss is defeated.
    var isCompleted: Bool = false

    // MARK: - Derived
    var isBossFloor: Bool {
        floorInAct == Self.floorsPerAct + 1
    }

    /// 1...33 (3 acts × (10 + boss))
    var globalFloor: Int {
        let floorsPerActIncludingBoss = Self.floorsPerAct + 1
        return max(1, (actIndex - 1) * floorsPerActIncludingBoss + floorInAct)
    }

    var globalFloorsTotal: Int {
        Self.actCount * (Self.floorsPerAct + 1)
    }

    var floorsRemainingToBoss: Int {
        max(0, Self.floorsPerAct + 1 - floorInAct)
    }

    mutating func advanceAfterClearingCurrentFloor() {
        guard !isCompleted else { return }

        if isBossFloor {
            if actIndex >= Self.actCount {
                isCompleted = true
                return
            }
            actIndex += 1
            floorInAct = 1
            return
        }

        floorInAct = min(Self.floorsPerAct + 1, floorInAct + 1)
    }

    /// Start of a run: Act 1, Floor 1.
    init() {
        self.actIndex = 1
        self.floorInAct = 1
        self.nonCombatStreak = 0
        self.roomOptions = []
    }
}
