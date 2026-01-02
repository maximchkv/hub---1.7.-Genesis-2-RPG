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

        battle = BattleState(
            floor: floor,
            enemyName: "Enemy",
            actionPoints: 2,
            hand: drawHand(),
            enemyIntent: EnemyIntent(kind: .attack),
            log: [CombatLogEntry("Battle started")],
            enemyAttackedThisTurn: false,
            cardLevels: levels
        )
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
            pushLog("Player: Power Strike — \(r.dealt) dmg (blocked \(r.blocked))")

        case .defend:
            let b = defendBlock(level: lvl)
            battle.playerBlock += b
            pushLog("Player: Defend — +\(b) block")

        case .doubleStrike:
            let hit = doubleStrikeHit(level: lvl)
            let r1 = applyDamage(hit, toHP: &battle.enemyHP, block: &battle.enemyBlock)
            pushLog("Player: Double 1 — \(r1.dealt) dmg (blocked \(r1.blocked))")
            let r2 = applyDamage(hit, toHP: &battle.enemyHP, block: &battle.enemyBlock)
            pushLog("Player: Double 2 — \(r2.dealt) dmg (blocked \(r2.blocked))")

        case .counterStance:
            let b = counterBlock(level: lvl)
            battle.playerBlock += b
            pushLog("Player: Counter Stance — +\(b) block")

            if battle.enemyAttackedThisTurn {
                let dmg = counterDamage(level: lvl)
                let r = applyDamage(dmg, toHP: &battle.enemyHP, block: &battle.enemyBlock)
                pushLog("Player: Counter — \(r.dealt) dmg (blocked \(r.blocked))")
            } else {
                pushLog("Player: Counter — no trigger")
            }
        }

        // Commit state
        self.battle = battle

        // Победа сразу после удара
        if battle.enemyHP <= 0 {
            winBattle()
            return
        }

        // Лог AP (сохраняем стиль)
        pushLog("Player used \(cardTitle(card.kind)) (-\(card.cost) AP)")
    }

    func endTurn() {
        guard var battle = battle else { return }

        pushLog("Player ended turn")

        // 4.1 Перед ходом врага — сброс флага атаки
        battle.enemyAttackedThisTurn = false

        // Enemy acts
        let acted = battle.enemyIntent
        pushLog("Enemy acted: \(acted.text) \(acted.icon)")

        switch acted.kind {
        case .attack:
            battle.enemyAttackedThisTurn = true
            let r = applyDamage(5, toHP: &battle.playerHP, block: &battle.playerBlock)
            pushLog("Enemy: Attack — \(r.dealt) dmg (blocked \(r.blocked))")

        case .defend:
            battle.enemyBlock += 5
            pushLog("Enemy: Defend — +5 block")

        case .counter:
            pushLog("Enemy: Counter (stub)")
        }

        // 4.3 Сжечь блок врага в конце его хода
        if battle.enemyBlock > 0 {
            pushLog("Enemy block burned: \(battle.enemyBlock) → 0")
            battle.enemyBlock = 0
        }

        // Commit mid-state
        self.battle = battle

        // 5) Победа/поражение
        if battle.enemyHP <= 0 {
            winBattle()
            return
        }
        if battle.playerHP <= 0 {
            loseBattle()
            return
        }

        // Новый intent на следующий ход
        cycleEnemyIntent()

        // Новый ход игрока: восстановить AP и раздать новую руку
        battle = self.battle ?? battle
        battle.actionPoints = 2
        battle.hand = drawHand()
        self.battle = battle

        pushLog("New turn: hand refreshed")
    }

    // MARK: - Log + Intent utilities
    private func pushLog(_ text: String) {
        guard var battle = battle else { return }
        battle.log.append(CombatLogEntry(text))
        if battle.log.count > 5 {
            battle.log.removeFirst(battle.log.count - 5)
        }
        self.battle = battle
    }

    private func cycleEnemyIntent() {
        guard var battle = battle else { return }
        let next: EnemyIntentKind
        switch battle.enemyIntent.kind {
        case .attack: next = .defend
        case .defend: next = .counter
        case .counter: next = .attack
        }
        battle.enemyIntent = EnemyIntent(kind: next)
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
