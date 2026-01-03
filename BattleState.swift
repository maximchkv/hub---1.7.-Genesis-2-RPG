struct BattleState {
    var floor: Int
    var enemyName: String

    // Базовые статы боя (011A/011B)
    var playerHP: Int = 20
    var playerBlock: Int = 0

    var enemyHP: Int = 20
    var enemyBlock: Int = 0

    // Карточная часть
    var actionPoints: Int
    var hand: [ActionCard]

    // Интент и лог
    var enemyIntent: EnemyIntent
    var log: [CombatLogEntry]

    // 011B: флаг — враг атаковал в этот ход
    var enemyAttackedThisTurn: Bool = false

    // 011B расширения (опционально можно будет хранить уровни карт)
    var cardLevels: [ActionCardKind: Int] = [:]

    // 015: набор карт, уже использованных в текущем ходу (по kind)
    var usedCardsThisTurn: Set<ActionCardKind> = []
}
