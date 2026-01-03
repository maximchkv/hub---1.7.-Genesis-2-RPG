import SwiftUI
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published var meta: PlayerMeta
    @Published var run: RunState? = nil
    @Published var route: Route = .start
    @Published var toast: String? = nil
    @Published var chest: ChestState? = nil
    @Published var battle: BattleState? = nil

    private let towerService = TowerService()

    // MVP card pool
    private let allCards: [ActionCardKind] = [
        .powerStrike,
        .defend,
        .doubleStrike,
        .counterStance
    ]

    private func drawHand() -> [ActionCard] {
        let shuffled = allCards.shuffled()
        return Array(shuffled.prefix(3)).map { ActionCard(kind: $0) }
    }

    init(meta: PlayerMeta) {
        self.meta = meta
    }

    convenience init() {
        self.init(meta: PlayerMeta())
    }

    // MARK: - Log helpers (unified format)
    private enum LogSide: String {
        case player = "PLAYER"
        case enemy  = "ENEMY"
        case system = "SYSTEM"
    }

    private func logText(_ side: LogSide, _ message: String) -> String {
        "[\(side.rawValue)] \(message)"
    }

    private func pushLog(_ battle: inout BattleState, side: LogSide, _ message: String) {
        battle.log.append(CombatLogEntry(id: UUID(), text: logText(side, message), isPlayer: side == .player))
    }

    // Divider marker for UI (not a visible text)
    private func pushDivider() {
        guard var b = battle else { return }
        b.log.append(CombatLogEntry(id: UUID(), text: "__DIVIDER__", isPlayer: false))
        battle = b
    }

    // MARK: - Navigation
    func goToStart() { route = .start }
    func goToHub() { route = .hub }
    func goToTower() { route = .tower }
    func goToCastle() { route = .castle }
    func goToCardLibrary() { route = .cardLibrary }
    func goToChest() { route = .chest }

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

    func resetRun() {
        run = nil
        battle = nil
        chest = nil
        route = .hub
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
            return
        }

        switch option.kind {
        case .combat:
            run.nonCombatStreak = 0
        case .chest:
            run.nonCombatStreak += 1
        }

        run.currentFloor += 1

        applyDayTick()

        meta.bestFloor = max(meta.bestFloor, run.currentFloor)

        run.roomOptions = towerService.generateRoomOptions(nonCombatStreak: run.nonCombatStreak)

        self.run = run

        switch option.kind {
        case .combat:
            startBattle()
        case .chest:
            chest = ChestState()
            route = .chest
        }
    }

    // DEBUG
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

    // MARK: - Chest
    private func generateArtifactForCurrentFloor() -> Artifact {
        let pool: [Artifact] = [
            Artifact(icon: "🪙", name: "Coin Charm", description: "A small charm that attracts coins.", incomeBonus: 1),
            Artifact(icon: "🔥", name: "Ember Idol", description: "Warmth that fuels production.", incomeBonus: 2),
            Artifact(icon: "🗿", name: "Stone Sigil", description: "A steady, reliable blessing.", incomeBonus: 1),
            Artifact(icon: "🌑", name: "Night Seal", description: "Quiet power from the dark.", incomeBonus: 2)
        ]
        return pool.randomElement() ?? Artifact(icon: "🪙", name: "Coin Charm", description: "A small charm that attracts coins.", incomeBonus: 1)
    }

    func openChest() {
        guard var chest else { return }
        if chest.isOpened { return }

        let art = generateArtifactForCurrentFloor()
        chest.isOpened = true
        chest.revealed = art
        self.chest = chest
    }

    func claimChestRewardAndContinue() {
        guard let chest, chest.isOpened, let art = chest.revealed else { return }
        meta.artifacts.append(art)
        toast = "\(art.icon) \(art.name) added (+\(art.incomeBonus)/day)"
        self.chest = nil
        route = .tower
    }

    // MARK: - Combat core
    private func applyDamage(
        _ amount: Int,
        toHP hp: inout Int,
        block: inout Int
    ) -> (blocked: Int, dealt: Int) {
        let blocked = min(block, amount)
        block -= blocked
        let dealt = amount - blocked
        if dealt > 0 {
            hp -= dealt
        }
        return (blocked, dealt)
    }

    // 011B: progression formulas
    private func baseValue(level: Int) -> Int {
        var v = 5
        if level <= 1 { return v }
        for _ in 2...level {
            v = Int((Double(v) * 1.25).rounded())
        }
        return v
    }

    private func powerStrikeDamage(level: Int) -> Int {
        baseValue(level: level)
    }

    private func defendBlock(level: Int) -> Int {
        baseValue(level: level)
    }

    private func doubleStrikeHit(level: Int) -> Int {
        Int((Double(powerStrikeDamage(level: level)) * 0.8).rounded())
    }

    private func counterDamage(level: Int) -> Int {
        Int((Double(powerStrikeDamage(level: level)) * 0.6).rounded())
    }

    private func counterBlock(level: Int) -> Int {
        Int((Double(defendBlock(level: level)) * 0.8).rounded())
    }

    // MARK: - Battle
    func startBattle() {
        let floor = run?.currentFloor ?? 1
        var levels: [ActionCardKind: Int] = [:]
        // По умолчанию все карты 1-го уровня (можно расширить позже)
        levels[.powerStrike] = 1
        levels[.defend] = 1
        levels[.doubleStrike] = 1
        levels[.counterStance] = 1

        var newBattle = BattleState(
            floor: floor,
            enemyName: "Enemy",
            actionPoints: 2,
            hand: drawHand(),
            enemyIntent: EnemyIntent(kind: .attack, value: 5),
            log: [],
            enemyAttackedThisTurn: false,
            cardLevels: levels
        )
        // Start-of-first-turn system log
        pushLog(&newBattle, side: .system, "New turn: hand refreshed")
        battle = newBattle
        route = .battle
    }

    func winBattle() {
        battle = nil
        toast = "Victory"
        route = .tower
    }

    func loseBattle() {
        battle = nil
        route = .defeat
    }

    func surrenderBattle() {
        battle = nil
        route = .hub
    }

    // MARK: - Cards (011B: все 4 карты)
    func playCard(_ card: ActionCard) {
        guard var battle = battle else { return }
        guard battle.actionPoints >= card.cost else { return }

        // тратим AP
        battle.actionPoints -= card.cost

        let lvl = battle.cardLevels[card.kind, default: 1]

        switch card.kind {
        case .powerStrike:
            let dmg = powerStrikeDamage(level: lvl)
            let r = applyDamage(dmg, toHP: &battle.enemyHP, block: &battle.enemyBlock)
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): dmg \(r.dealt) (blocked \(r.blocked))")

        case .defend:
            let b = defendBlock(level: lvl)
            battle.playerBlock += b
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): block +\(b)")

        case .doubleStrike:
            let hit = doubleStrikeHit(level: lvl)
            let r1 = applyDamage(hit, toHP: &battle.enemyHP, block: &battle.enemyBlock)
            let r2 = applyDamage(hit, toHP: &battle.enemyHP, block: &battle.enemyBlock)
            let totalDealt = r1.dealt + r2.dealt
            let totalBlocked = r1.blocked + r2.blocked
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): dmg \(totalDealt) (blocked \(totalBlocked))")

        case .counterStance:
            let b = counterBlock(level: lvl)
            battle.playerBlock += b
            // В этом же ходе карта не наносит урон; эффект — блок
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): block +\(b)")
        }

        // Commit state
        self.battle = battle

        // Победа сразу после удара
        if battle.enemyHP <= 0 {
            winBattle()
            return
        }
    }

    func endTurn() {
        guard var b = battle else { return }

        // 1) Закрыли ход игрока
        pushLog(&b, side: .player, "End turn")
        battle = b

        // 2) Разделитель перед ходом врага
        pushDivider()

        // 3) Ход врага = действие текущего intent
        guard var b2 = battle else { return }
        performEnemyTurn(&b2)
        // if performEnemyTurn ended battle (player died), it will have called loseBattle()
        if self.battle == nil { return }
        battle = b2

        // 4) Разделитель после хода врага
        pushDivider()

        // 5) Новый ход игрока: обновляем intent, AP, руку
        guard var b3 = battle else { return }
        b3.enemyIntent = rollEnemyIntent()
        b3.actionPoints = 2
        b3.hand = drawHand()
        pushLog(&b3, side: .system, "New turn: hand refreshed")
        battle = b3
    }

    // MARK: - Enemy turn helpers
    private func performEnemyTurn(_ b: inout BattleState) {
        let intent = b.enemyIntent

        switch intent.kind {
        case .attack:
            b.enemyAttackedThisTurn = true
            let dmg = max(0, intent.value)
            let r = applyDamage(dmg, toHP: &b.playerHP, block: &b.playerBlock)
            pushLog(&b, side: .enemy, "Attack: dmg \(r.dealt) (blocked \(r.blocked))")
            if b.playerHP <= 0 {
                // commit before ending
                self.battle = b
                loseBattle()
                return
            }

        case .defend:
            let blockGain = max(0, intent.value)
            b.enemyBlock += blockGain
            pushLog(&b, side: .enemy, "Defend: block +\(blockGain)")

        case .counter:
            // Minimal implementation: preparation stance
            pushLog(&b, side: .enemy, "Counter")
        }
    }

    private func rollEnemyIntent() -> EnemyIntent {
        let roll = Int.random(in: 0..<100)
        if roll < 50 { return EnemyIntent(kind: .attack, value: 5) }
        if roll < 80 { return EnemyIntent(kind: .defend, value: 5) }
        return EnemyIntent(kind: .counter, value: 0)
    }

    // MARK: - Enemy turn (legacy, unused)
    private func enemyTurn() {
        guard var battle = battle else { return }

        let intent = battle.enemyIntent

        switch intent.kind {
        case .attack:
            battle.enemyAttackedThisTurn = true
            let r = applyDamage(5, toHP: &battle.playerHP, block: &battle.playerBlock)
            pushLog(&battle, side: .enemy, "\(intent.text): dmg \(r.dealt) (blocked \(r.blocked))")

        case .defend:
            battle.enemyBlock += 5
            pushLog(&battle, side: .enemy, "\(intent.text): block +5")

        case .counter:
            // стойка/подготовка — без немедленного эффекта
            pushLog(&battle, side: .enemy, "\(intent.text): no effect")
        }

        // Roll next intent (simple cycle)
        let nextKind: EnemyIntentKind
        switch battle.enemyIntent.kind {
        case .attack: nextKind = .defend
        case .defend: nextKind = .counter
        case .counter: nextKind = .attack
        }
        battle.enemyIntent = EnemyIntent(kind: nextKind)

        self.battle = battle
    }

    private func cardTitle(_ kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "Power Strike"
        case .defend: return "Guard"
        case .doubleStrike: return "Double Strike"
        case .counterStance: return "Counter Stance"
        }
    }
}
