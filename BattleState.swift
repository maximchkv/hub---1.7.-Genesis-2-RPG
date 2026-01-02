struct BattleState: Codable {
    var floor: Int
    var enemyName: String
    var enemyHP: Int
    var playerHP: Int

    var actionPoints: Int
    var hand: [ActionCard]

    var enemyIntent: EnemyIntent
    var log: [CombatLogEntry]
}
