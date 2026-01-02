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

    // MARK: - Battle
    func startBattle() {
        let floor = run?.currentFloor ?? 1
        battle = BattleState(
            floor: floor,
            enemyName: "Enemy",
            enemyHP: 20,
            playerHP: 20,
            actionPoints: 2,
            hand: drawHand(),
            enemyIntent: EnemyIntent(kind: .attack),
            log: [CombatLogEntry("Battle started")]
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

    // MARK: - Cards (no combat logic yet)
    func playCard(_ card: ActionCard) {
        guard var battle = battle else { return }
        guard battle.actionPoints >= card.cost else { return }

        battle.actionPoints -= card.cost
        self.battle = battle

        pushLog("Player used \(cardTitle(card.kind)) (-\(card.cost) AP)")
    }

    func endTurn() {
        guard var battle = battle else { return }

        pushLog("Player ended turn")

        // Enemy "acts" (stub) — делает то, что было намерением
        let acted = battle.enemyIntent
        pushLog("Enemy acted: \(acted.text) \(acted.icon)")

        // Затем выбираем намерение на следующий ход
        cycleEnemyIntent()

        // Логируем следующее намерение (оно же показывается в UI сверху)
        let next = (self.battle ?? battle).enemyIntent
        pushLog("Next intent: \(next.text) \(next.icon)")

        // New turn: reset AP and draw new hand
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
