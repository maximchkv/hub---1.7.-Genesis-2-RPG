struct PlayerMeta: Codable {
    var days: Int = 0
    var gold: Int = 0
    var bestFloor: Int = 0
    var artifacts: [Artifact] = []

    // MVP: базовый доход + бонусы от артефактов
    var incomePerDay: Int {
        let bonus = artifacts.reduce(0) { $0 + $1.incomeBonus }
        return 3 + bonus
    }
}
