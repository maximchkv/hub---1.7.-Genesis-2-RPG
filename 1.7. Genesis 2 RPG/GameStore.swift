import SwiftUI
import Combine

// 023C: Build sheet candidate model
struct BuildCandidate: Identifiable, Equatable {
    let id = UUID()
    let kind: GameStore.BuildingKind
    let title: String
    let emoji: String
    let incomePerDay: Int
    let blurb: String
}

enum CastleUIMode: String {
    case idle
    case build
    case upgrade
}

@MainActor
final class GameStore: ObservableObject {
    @Published var meta: PlayerMeta
    @Published var run: RunState? = nil
    @Published var route: Route = .start
    @Published var toast: String? = nil
    @Published var chest: ChestState? = nil
    @Published var battle: BattleState? = nil
    @Published var event: EventState? = nil

    // Reward (currently not routed, but referenced by RewardView.swift)
    @Published var reward: RewardState? = nil

    // Tracks the room currently being resolved (used for post-room progression)
    @Published var activeRoomKind: RoomKind? = nil

    // Castle routing (021B)
    enum CastleRoute: Equatable {
        case main
        case upgrade
        case relics
    }
    @Published var castleRoute: CastleRoute = .main

    // MARK: - Castle (MVP)
    enum CastleMode: String {
        case build = "Build"
        case upgrade = "Upgrade"
        case artifacts = "Artifacts"
    }

    // Building type currently used in the project (acts as "BuildingType" in the spec)
    enum BuildingKind: CaseIterable, Codable, Equatable {
        case mine
        case farm

        var emoji: String {
            switch self {
            case .mine: return "⛏️"
            case .farm: return "🌾"
            }
        }

        var title: String {
            switch self {
            case .mine: return "Mine"
            case .farm: return "Farm"
            }
        }
    }

    // MARK: - Castle tile state (027A1)
    enum CastleTileState: Codable, Equatable {
        case empty
        case constructing(type: BuildingKind)
        case built(type: BuildingKind, level: Int)
        case upgrading(type: BuildingKind, fromLevel: Int)

        var buildingType: BuildingKind? {
            switch self {
            case .empty: return nil
            case .constructing(let type): return type
            case .built(let type, _): return type
            case .upgrading(let type, _): return type
            }
        }

        var displayLevel: Int? {
            switch self {
            case .built(_, let level):
                return max(1, level)
            case .upgrading(_, let fromLevel):
                return max(1, fromLevel)
            default:
                return nil
            }
        }

        var isBusy: Bool {
            switch self {
            case .constructing, .upgrading: return true
            default: return false
            }
        }
    }

    struct CastleTile: Identifiable, Codable, Equatable {
        let id: Int // 0...24
        var state: CastleTileState = .empty

        var building: BuildingKind? {
            state.buildingType
        }

        var level: Int {
            switch state {
            case .built(_, let level): return max(1, level)
            case .upgrading(_, let fromLevel): return max(1, fromLevel)
            default:
                return 0
            }
        }

        var isUnderConstruction: Bool {
            if case .constructing = state { return true }
            return false
        }

        var isEmpty: Bool {
            if case .empty = state { return true }
            return false
        }

        var canUpgrade: Bool {
            if case .built = state { return true }
            return false
        }
    }

    @Published var castleMode: CastleMode = .build
    @Published var castleTiles: [CastleTile] = (0..<25).map { CastleTile(id: $0) }

    var castleBuildingsCount: Int {
        castleTiles.filter {
            if case .built = $0.state { return true }
            return false
        }.count
    }

    var castleFreeTilesCount: Int {
        castleTiles.filter {
            if case .empty = $0.state { return true }
            return false
        }.count
    }

    // MARK: - Castle computed stats
    var castleIncomePerDay: Int {
        castleTiles.reduce(0) { acc, t in
            switch t.state {
            case .built(let type, let level):
                return acc + type.incomePerDay(level: level)
            default:
                return acc
            }
        }
    }

    func setCastleMode(_ mode: CastleMode) {
        castleMode = mode
        toast = "\(mode.rawValue) mode"
    }

    func isCastleTileEmpty(_ index: Int) -> Bool {
        guard let idx = castleTiles.firstIndex(where: { $0.id == index }) else { return false }
        if case .empty = castleTiles[idx].state { return true }
        return false
    }

    func isCastleTileUpgradeable(_ index: Int) -> Bool {
        guard let idx = castleTiles.firstIndex(where: { $0.id == index }) else { return false }
        if case .built = castleTiles[idx].state { return true }
        return false
    }

    struct CastleTileUIInfo {
        let title: String
        let icon: String
        let level: Int
        let incomePerDay: Int
    }

    func castleTileInfo(_ index: Int) -> CastleTileUIInfo? {
        guard let idx = castleTiles.firstIndex(where: { $0.id == index }) else { return nil }
        let t = castleTiles[idx]
        guard let b = t.building else { return nil }
        let lvl = max(1, t.level)
        return CastleTileUIInfo(
            title: b.title,
            icon: b.emoji,
            level: lvl,
            incomePerDay: b.incomePerDay(level: lvl)
        )
    }

    private let towerService = TowerService()

    // MVP card pool
    private let allCards: [ActionCardKind] = [
        .powerStrike,
        .defend,
        .doubleStrike,
        .counterStance,
        // 031B: include status cards in pool (for testing)
        .bleedPlus2,
        .weakPlus1,
        .stun1,
        // Синергийные карты
        .bleedStrike,
        .weakDefend
    ]

    private func drawHand() -> [ActionCard] {
        let shuffled = allCards.shuffled()
        return Array(shuffled.prefix(5)).map { ActionCard(kind: $0) }
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
        let kind: CombatLogEntry.Kind = (side == .system) ? .system : .normal
        battle.log.append(CombatLogEntry(id: UUID(), text: logText(side, message), isPlayer: side == .player, kind: kind))
    }

    private func pushDivider() {
        guard var b = battle else { return }
        b.log.append(CombatLogEntry(id: UUID(), text: "__DIVIDER__", isPlayer: false, kind: .separator))
        battle = b
    }

    private func pushSeparator() { pushDivider() }

    private func pushSystem(_ text: String) {
        guard var b = battle else { return }
        pushLog(&b, side: .system, text)
        battle = b
    }

    private func pushEnemy(_ text: String) {
        guard var b = battle else { return }
        pushLog(&b, side: .enemy, text)
        battle = b
    }

    // MARK: - Navigation
    func goToStart() { route = .start }
    func goToHub() { route = .hub }

    /// Entry point into the Tower from Hub: shows the splash once.
    func goToTowerEntry() {
        route = .towerSplash

        if run == nil {
            startRun(routeToHub: false)
        }

        refreshRoomOptions()
    }

    func goToTower() {
        route = .tower

        if run == nil {
            startRun(routeToHub: false)
        }

        refreshRoomOptions()
    }

    func goToCastle() {
        route = .castle
        castleRoute = .main
    }

    func goToCardLibrary() { route = .cardLibrary }
    func goToChest() { route = .chest }

    func goToCastleUpgrade() { castleRoute = .upgrade }
    func goToCastleRelics() { castleRoute = .relics }
    func backToCastleMain() { castleRoute = .main }
    
    // MARK: - Collection
    func unlockCard(_ kind: ActionCardKind) {
        let wasUnlocked = meta.collection.isUnlocked(kind)
        meta.unlockCard(kind)
        if !wasUnlocked {
            toast = "Карта разблокирована: \(cardTitle(kind))"
        }
    }
    
    func incrementCardUsage(_ kind: ActionCardKind) {
        meta.incrementCardUsage(kind)
    }

    // MARK: - Run
    func startRun(routeToHub: Bool = true) {
        var newRun = RunState()
        
        // Generate the tower map for Act 1
        let actMap = towerService.generateActMap(actIndex: 1)
        newRun.towerMap = actMap
        
        // Set legacy roomOptions from map's reachable nodes for backward compat
        newRun.roomOptions = actMap.reachableRoomOptions()
        
        run = newRun
        
        // Auto-unlock base cards on first run
        if meta.collection.unlockedCards.isEmpty {
            unlockBaseCards()
        }
        
        if routeToHub {
            route = .hub
        }
    }
    
    private func unlockBaseCards() {
        for cardKind in ActionCardKind.allCases where cardKind.isBaseCard {
            meta.unlockCard(cardKind)
        }
    }

    func endRun() {
        run = nil
        route = .start
    }

    func resetRun() {
        run = nil
        battle = nil
        chest = nil
        event = nil
        activeRoomKind = nil
        route = .hub
    }

    // MARK: - Tower
    func refreshRoomOptions() {
        guard var r = run else { return }
        
        // Use tower map if available
        if let map = r.towerMap {
            r.roomOptions = map.reachableRoomOptions()
        } else {
            // Legacy fallback
            r.roomOptions = towerService.generateRoomOptions(run: r)
        }
        run = r
    }
    
    /// Generate a new map for a new act
    private func generateMapForNewAct() {
        guard var r = run else { return }
        let actMap = towerService.generateActMap(actIndex: r.actIndex)
        r.towerMap = actMap
        r.roomOptions = actMap.reachableRoomOptions()
        run = r
    }

    func selectRoom(_ option: RoomOption) {
        guard var r = run else { return }
        if option.kind == .chest && option.isLocked {
            return
        }
        
        // Update tower map position
        if let nodeId = r.nodeIdForRoom(option) {
            r.moveToMapNode(nodeId: nodeId)
            run = r
        }

        activeRoomKind = option.kind

        switch option.kind {
        case .combat:
            startBattle(kind: .combat)
        case .chest:
            chest = ChestState()
            route = .chest
        case .elite:
            startBattle(kind: .elite)
        case .boss:
            startBattle(kind: .boss)
        case .rest:
            route = .rest
        case .event:
            event = EventState(
                title: "A Stranger",
                text: "A hooded figure offers you a choice.",
                options: [
                    .init(title: "Accept the gift", toast: "You feel a strange warmth."),
                    .init(title: "Walk away", toast: "You stay cautious and move on.")
                ]
            )
            route = .event
        }
    }

    func chooseEventOption(_ option: EventState.Option) {
        toast = option.toast
        event = nil
        completeNonCombatRoomAndContinue(kind: .event)
    }

    func completeNonCombatRoomAndContinue(kind: RoomKind) {
        completeRoomAndMoveForward(kind: kind, didWinCombat: nil)
    }

    func restHealAndContinue() {
        let healAmount = 6
        guard var r = run else {
            route = .tower
            return
        }
        let before = r.playerHP
        r.playerHP = min(r.playerMaxHP, r.playerHP + healAmount)
        run = r
        toast = "Rest: +\(r.playerHP - before) HP"
        completeNonCombatRoomAndContinue(kind: .rest)
    }

    func finishRunAndReturnToHub() {
        run = nil
        battle = nil
        chest = nil
        event = nil
        activeRoomKind = nil
        route = .hub
    }

    // DEBUG
    func debugDayTick() {
        meta.days += 1
        meta.gold += 3
        if let run {
            meta.bestFloor = max(meta.bestFloor, run.globalFloor)
        }
    }

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
        return pool.randomElement() ?? Artifact(icon: "🪙", name: "Coin Charm", description: "A small charm", incomeBonus: 1)
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
        completeNonCombatRoomAndContinue(kind: .chest)
    }

    // MARK: - Combat core (031A/031B integrated)
    private func baseValue(level: Int) -> Int {
        var v = 5
        if level <= 1 { return v }
        for _ in 2...level {
            v = Int((Double(v) * 1.25).rounded())
        }
        return v
    }

    private func powerStrikeDamage(level: Int) -> Int { baseValue(level: level) }
    private func defendBlock(level: Int) -> Int { baseValue(level: level) }
    private func doubleStrikeHit(level: Int) -> Int { Int((Double(powerStrikeDamage(level: level)) * 0.8).rounded()) }
    private func counterDamage(level: Int) -> Int { Int((Double(powerStrikeDamage(level: level)) * 0.6).rounded()) }
    private func counterBlock(level: Int) -> Int { Int((Double(defendBlock(level: level)) * 0.8).rounded()) }

    // Runtime enemy helpers (spec)
    private func enemyAttackValue() -> Int { 5 }
    private func enemyBlockValue() -> Int { 5 }

    // Counter-Stance Lv1 constants (027C-A)
    private func counterStanceBlockValue() -> Int { 4 }
    private func counterStanceAttackValue() -> Int { 3 }

    private func intentFromPattern(_ battle: BattleState) -> EnemyIntent {
        guard !battle.enemyPattern.isEmpty else {
            return EnemyIntent(kind: .attack, value: 5)
        }

        let move = battle.enemyPattern[battle.enemyPatternIndex].kind
        switch move {
        case .attack:
            return EnemyIntent(kind: .attack, value: 5)
        case .defend:
            return EnemyIntent(kind: .defend, value: 5)
        case .counterStance:
            return EnemyIntent(kind: .counterStance, value: 0)
        case .doubleStrikeFixed4:
            return EnemyIntent(kind: .doubleStrikeFixed4, value: 0)
        }
    }

    // MARK: - Battle
    func startBattle(kind: RoomKind) {
        // kind is expected to be .combat / .elite / .boss
        activeRoomKind = kind
        let enemy = RuntimeEnemyCatalog.randomV1()

        let floorLabel = run?.globalFloor ?? 1

        // Structural-only tuning: mark tougher fights
        let enemyHP: Int = (kind == .boss) ? 40 : (kind == .elite ? 28 : 20)
        let playerHP: Int = run?.playerHP ?? 20

        var newBattle = BattleState(
            floor: floorLabel,
            enemyName: (kind == .boss) ? "Boss: \(enemy.name)" : (kind == .elite ? "Elite: \(enemy.name)" : enemy.name),
            playerHP: playerHP,
            playerBlock: 0,
            enemyHP: enemyHP,
            enemyBlock: 0,
            actionPoints: 3,
            hand: drawHand(),
            enemyIntent: EnemyIntent(kind: .attack, value: 5),
            log: [],
            enemyAttackedThisTurn: false,
            cardLevels: run?.cardLevels ?? [:]
        )
        newBattle.phase = .player

        // Runtime enemy fields
        newBattle.enemyRuntimeKind = enemy.kind
        newBattle.enemyRole = enemy.role
        newBattle.enemyPattern = enemy.pattern
        newBattle.enemyPatternIndex = 0

        // First intent from pattern
        newBattle.enemyIntent = intentFromPattern(newBattle)

        battle = newBattle
        route = .battle

        pushSeparator()
        pushSystem("New turn: hand refreshed")
    }

    func winBattle() {
        // Progression happens on victory (not on room selection)
        let kind = activeRoomKind ?? .combat
        // Persist HP into the run before leaving combat
        if var r = run, let b = battle {
            r.playerHP = max(0, min(r.playerMaxHP, b.playerHP))
            run = r
        }

        battle = nil
        toast = (kind == .boss) ? "Boss defeated" : "Victory"

        // Reward gate (v1): choose 1 card upgrade after every win
        reward = generateReward()
        route = .reward
    }

    func loseBattle() {
        battle = nil
        route = .defeat
    }

    func surrenderBattle() {
        battle = nil
        activeRoomKind = nil
        route = .hub
    }

    // MARK: - Post-room progression (structure v1)
    private func completeRoomAndMoveForward(kind: RoomKind, didWinCombat: Bool?) {
        guard var r = run else {
            route = .hub
            return
        }

        // Update non-combat streak (elite/boss are combats)
        switch kind {
        case .combat, .elite, .boss:
            r.nonCombatStreak = 0
        case .chest, .rest, .event:
            r.nonCombatStreak += 1
        }

        // Unified day tick after clearing a floor
        advanceDayTick()
        
        // Mark current map node as completed
        r.completeCurrentMapNode()
        
        // Track if we're about to change acts
        let previousActIndex = r.actIndex

        // Advance run structure
        r.advanceAfterClearingCurrentFloor()

        // Best floor uses global floor
        meta.bestFloor = max(meta.bestFloor, r.globalFloor)

        // Clear active room marker
        activeRoomKind = nil

        // End condition
        if r.isCompleted {
            run = r
            route = .victory
            return
        }
        
        // Check if act changed - need to generate new map
        if r.actIndex != previousActIndex {
            // Act changed, generate new map
            let actMap = towerService.generateActMap(actIndex: r.actIndex)
            r.towerMap = actMap
            r.roomOptions = actMap.reachableRoomOptions()
        } else if let map = r.towerMap {
            // Same act, update room options from map
            r.roomOptions = map.reachableRoomOptions()
        } else {
            // Legacy fallback
            r.roomOptions = towerService.generateRoomOptions(run: r)
        }
        
        run = r
        route = .tower
    }

    // MARK: - Reward (v1)
    private func generateReward() -> RewardState {
        // Pick 3 unique upgrade options from a stable pool.
        // (Full deckbuilding/rarities come later.)
        let pool: [ActionCardKind] = [
            .powerStrike, .defend, .doubleStrike, .counterStance,
            .bleedPlus2, .weakPlus1, .stun1,
            .bleedStrike, .weakDefend
        ]
        let options = Array(Set(pool.shuffled().prefix(3)))
        // Ensure exactly 3 when Set collapses (rare)
        let fixed = (options.count == 3) ? options : Array(pool.shuffled().prefix(3))
        return RewardState(options: fixed)
    }

    func claimReward(_ kind: ActionCardKind) {
        guard var r = run else {
            reward = nil
            route = .tower
            return
        }

        let old = r.cardLevels[kind] ?? 1
        r.cardLevels[kind] = old + 1
        run = r
        
        // Unlock card in collection if first time
        unlockCard(kind)

        toast = "Upgraded \(kind.rawValue) → Lv\(old + 1)"
        reward = nil

        // Now advance the floor and return to tower/victory
        let roomKind = activeRoomKind ?? .combat
        completeRoomAndMoveForward(kind: roomKind, didWinCombat: true)
    }

    // MARK: - Cards
    func playCard(_ card: ActionCard) {
        // 031A: block playing if stunned
        if let b = battle, b.playerSkipTurn {
            pushSystem("You are stunned and cannot act.")
            return
        }

        guard var battle = battle else { return }
        guard battle.phase == .player else { return }
        if battle.usedCardsThisTurn.contains(card.kind) { return }
        guard battle.actionPoints >= card.cost else { return }
        battle.actionPoints -= card.cost

        let lvl = battle.cardLevels[card.kind, default: 1]

        switch card.kind {
        case .powerStrike:
            let base = powerStrikeDamage(level: lvl)
            let dmg = battle.modifiedOutgoingWeaponDamage(base, from: .player)
            let beforeHP = battle.enemyHP
            let beforeBlock = battle.enemyBlock
            battle.dealDamage(amount: dmg, to: .enemy, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.enemyHP)
            let blocked = max(0, beforeBlock - battle.enemyBlock)
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): dmg \(dealt) (blocked \(blocked))")

        case .defend:
            let bVal = defendBlock(level: lvl)
            battle.playerBlock += bVal
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): block +\(bVal)")

        case .doubleStrike:
            let hit = doubleStrikeHit(level: lvl)
            let dmg1 = battle.modifiedOutgoingWeaponDamage(hit, from: .player)
            let dmg2 = battle.modifiedOutgoingWeaponDamage(hit, from: .player)
            let beforeHP = battle.enemyHP
            let beforeBlock = battle.enemyBlock
            battle.dealDamage(amount: dmg1, to: .enemy, isWeaponDamage: true)
            battle.dealDamage(amount: dmg2, to: .enemy, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.enemyHP)
            let blocked = max(0, beforeBlock - battle.enemyBlock)
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): dmg \(dealt) (blocked \(blocked))")

        case .counterStance:
            let bVal = counterStanceBlockValue()
            let base = counterStanceAttackValue()
            battle.playerBlock += bVal
            let dmg = battle.modifiedOutgoingWeaponDamage(base, from: .player)
            let beforeHP = battle.enemyHP
            let beforeBlock = battle.enemyBlock
            battle.dealDamage(amount: dmg, to: .enemy, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.enemyHP)
            let blocked = max(0, beforeBlock - battle.enemyBlock)
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): block +\(bVal), dmg \(dealt) (blocked \(blocked))")

        // 031B: Status cards
        case .bleedPlus2:
            battle.addStatus(.bleed, stacks: 2, to: .enemy)
            pushLog(&battle, side: .player, "Player uses Кровоток → Enemy: Кровоток +2")

        case .weakPlus1:
            battle.addStatus(.weak, stacks: 1, to: .enemy)
            pushLog(&battle, side: .player, "Player uses Ослабить → Enemy: Слабость +1")

        case .stun1:
            battle.addStatus(.stun, stacks: 1, to: .enemy)
            pushLog(&battle, side: .player, "Player uses Оглушить → Enemy: Оглушение 1")
        
        // Синергийные карты
        case .bleedStrike:
            let enemyBleedStacks = battle.enemyStatuses.first(where: { $0.type == .bleed })?.stacks ?? 0
            if enemyBleedStacks > 0 {
                // Если у врага есть кровотечение: урон = стаки × 3
                let dmg = enemyBleedStacks * 3
                let beforeHP = battle.enemyHP
                let beforeBlock = battle.enemyBlock
                battle.dealDamage(amount: dmg, to: .enemy, isWeaponDamage: true)
                let dealt = max(0, beforeHP - battle.enemyHP)
                let blocked = max(0, beforeBlock - battle.enemyBlock)
                pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): dmg \(dealt) (blocked \(blocked), от кровотечения ×\(enemyBleedStacks))")
            } else {
                // Если у врага нет кровотечения: наложить Bleed +2
                battle.addStatus(.bleed, stacks: 2, to: .enemy)
                pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): Кровоток +2")
            }
        
        case .weakDefend:
            battle.addStatus(.weak, stacks: 1, to: .enemy)
            battle.playerBlock += 4
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): Слабость +1 врагу, блок +4")
            
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            // Placeholders should never be playable
            break
        }

        battle.usedCardsThisTurn.insert(card.kind)
        self.battle = battle
        
        // Track card usage in collection
        incrementCardUsage(card.kind)

        if battle.enemyHP <= 0 {
            winBattle()
            return
        }
    }

    func endTurn() {
        guard var b = battle else { return }
        pushLog(&b, side: .player, "End turn")
        // Add a visual divider immediately after End turn (FIX-BOOT-032)
        b.log.append(CombatLogEntry(id: UUID(), text: "__DIVIDER__", isPlayer: false, kind: .separator))
        b.phase = .enemy

        // 031A: Start of enemy turn (statuses)
        var out = b.startOfTurn(for: .enemy)
        for line in out.logLines {
            b.log.append(CombatLogEntry.system(line))
        }

        // Enemy phase: per spec (only if not stunned)
        if !out.didSkipTurn {
            pushSeparator()
            self.battle = b
            performEnemyTurn()
            if let after = self.battle { b = after }
            cycleEnemyIntent()
            if let after2 = self.battle { b = after2 }
            pushSeparator()
        }

        // 031A: Start of player turn (statuses)
        out = b.startOfTurn(for: .player)
        for line in out.logLines {
            b.log.append(CombatLogEntry.system(line))
        }

        // Prepare next player turn
        b.playerBlock = 0
        b.actionPoints = 3
        b.hand = drawHand()
        b.usedCardsThisTurn.removeAll()
        b.phase = .player
        pushLog(&b, side: .system, "New turn: hand refreshed")
        battle = b
    }

    private func performEnemyTurn() {
        guard var battle = battle else { return }

        func applyEnemyOnHitStatus() {
            switch battle.enemyRuntimeKind {
            case .punisher:
                battle.addStatus(.vulnerable, stacks: 1, to: .player)
                pushLog(&battle, side: .enemy, "Enemy attack → Player: Уязвимость +1")
            case .graphiteGolem:
                battle.addStatus(.weak, stacks: 1, to: .player)
                pushLog(&battle, side: .enemy, "Enemy attack → Player: Слабость +1")
            case .zesurumiMonks:
                battle.addStatus(.bleed, stacks: 2, to: .player)
                pushLog(&battle, side: .enemy, "Enemy attack → Player: Кровоток +2")
            case .feyanchа:
                battle.addStatus(.bleed, stacks: 1, to: .player)
                pushLog(&battle, side: .enemy, "Enemy attack → Player: Кровоток +1")
            }
        }

        switch battle.enemyIntent.kind {
        case .attack:
            let base = enemyAttackValue()
            let dmg = battle.modifiedOutgoingWeaponDamage(base, from: .enemy)
            let beforeHP = battle.playerHP
            let beforeBlock = battle.playerBlock
            battle.dealDamage(amount: dmg, to: .player, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.playerHP)
            let blocked = max(0, beforeBlock - battle.playerBlock)
            pushLog(&battle, side: .enemy, "Attack: dmg \(dealt) (blocked \(blocked))")
            applyEnemyOnHitStatus()
            if battle.playerHP <= 0 {
                self.battle = battle
                loseBattle()
                return
            }

        case .defend:
            let block = enemyBlockValue()
            battle.enemyBlock += block
            pushLog(&battle, side: .enemy, "Defend: block +\(block)")

        case .counterStance:
            let bVal = counterStanceBlockValue()
            let base = counterStanceAttackValue()
            battle.enemyBlock += bVal
            let dmg = battle.modifiedOutgoingWeaponDamage(base, from: .enemy)
            let beforeHP = battle.playerHP
            let beforeBlock = battle.playerBlock
            battle.dealDamage(amount: dmg, to: .player, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.playerHP)
            let blocked = max(0, beforeBlock - battle.playerBlock)
            pushLog(&battle, side: .enemy, "Counter Stance: block +\(bVal), dmg \(dealt) (blocked \(blocked))")
            applyEnemyOnHitStatus()
            if battle.playerHP <= 0 {
                self.battle = battle
                loseBattle()
                return
            }

        case .doubleStrikeFixed4:
            let base = 4
            let dmg1 = battle.modifiedOutgoingWeaponDamage(base, from: .enemy)
            let dmg2 = battle.modifiedOutgoingWeaponDamage(base, from: .enemy)
            let beforeHP = battle.playerHP
            let beforeBlock = battle.playerBlock
            battle.dealDamage(amount: dmg1, to: .player, isWeaponDamage: true)
            applyEnemyOnHitStatus()
            battle.dealDamage(amount: dmg2, to: .player, isWeaponDamage: true)
            applyEnemyOnHitStatus()
            let dealt = max(0, beforeHP - battle.playerHP)
            let blocked = max(0, beforeBlock - battle.playerBlock)
            pushLog(&battle, side: .enemy, "Double Strike: dmg \(dealt) (blocked \(blocked))")
            if battle.playerHP <= 0 {
                self.battle = battle
                loseBattle()
                return
            }

        case .counter:
            pushLog(&battle, side: .enemy, "Counter")
        }

        self.battle = battle
    }

    func cycleEnemyIntent() {
        guard var battle = battle else { return }
        battle.advanceEnemyPattern()
        battle.enemyIntent = intentFromPattern(battle)
        self.battle = battle
    }

    private func cardTitle(_ kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "Power Strike"
        case .defend: return "Guard"
        case .doubleStrike: return "Double Strike"
        case .counterStance: return "Counter Stance"
        case .bleedPlus2: return "Кровоток"
        case .weakPlus1: return "Ослабить"
        case .stun1: return "Оглушить"
        case .bleedStrike: return "Кровавый удар"
        case .weakDefend: return "Ослабляющий щит"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "???"
        }
    }

    // MARK: - Castle UI State
    @Published var castleModeUI: CastleUIMode = .idle
    @Published var isBuildSheetPresented: Bool = false
    @Published var isUpgradeSheetPresented: Bool = false
    @Published var selectedCastleTileIndex: Int? = nil

    @Published var selectedBuildTileIndex: Int? = nil
    @Published var buildCandidates: [BuildCandidate] = [
        BuildCandidate(kind: .farm, title: "Farm", emoji: "🌾", incomePerDay: 1, blurb: "+1 / day"),
        BuildCandidate(kind: .mine, title: "Mine", emoji: "⛏️", incomePerDay: 2, blurb: "+2 / day")
    ]

    func setCastleMode(_ mode: CastleUIMode) {
        if castleModeUI == mode {
            castleModeUI = .idle
        } else {
            castleModeUI = mode
        }
    }

    func onTileTapped(_ tile: CastleTile) {
        switch castleModeUI {
        case .build:
            guard tile.isEmpty else { return }
            openBuildSheet(forTile: tile.id)
        case .upgrade:
            guard tile.canUpgrade else { return }
            selectedCastleTileIndex = tile.id
            isUpgradeSheetPresented = true
        case .idle:
            if tile.isEmpty {
                openBuildSheet(forTile: tile.id)
            } else {
                selectedCastleTileIndex = tile.id
                isUpgradeSheetPresented = true
            }
        }
    }

    func handleCastleTileTap(index: Int, isEmpty: Bool) {
        guard let tile = castleTiles.first(where: { $0.id == index }) else { return }
        onTileTapped(tile)
    }

    func closeBuildSheet() {
        isBuildSheetPresented = false
        castleModeUI = .idle
    }

    func closeUpgradeSheet() {
        isUpgradeSheetPresented = false
        castleModeUI = .idle
    }

    func openBuildSheet(forTile index: Int) {
        selectedBuildTileIndex = index
        isBuildSheetPresented = true
    }

    func cancelBuildSheet() {
        isBuildSheetPresented = false
        selectedBuildTileIndex = nil
        castleModeUI = .idle
    }

    func confirmBuild(_ candidate: BuildCandidate) {
        guard let index = selectedBuildTileIndex else { return }
        guard castleTiles.indices.contains(index) else { return }

        // Apply build directly (was: buildTile(...), but that method doesn't exist)
        castleTiles[index].state = .built(type: candidate.kind, level: 1)
        castleRecomputeStats()

        isBuildSheetPresented = false
        selectedBuildTileIndex = nil
        castleModeUI = .idle
    }

    func castleRecomputeStats() {}

    func advanceDayTick() {
        meta.days += 1
        let incomeBeforeApplying = castleIncomePerDay
        meta.gold += incomeBeforeApplying
        applyCastlePending()
        recomputeCastleEconomy()
        toast = "Day +1  •  Gold +\(incomeBeforeApplying)"
        for tile in castleTiles {
            if case .built(_, let level) = tile.state {
                assert(level >= 1)
            }
        }
    }

    func castleAdvanceDay() { advanceDayTick() }

    private func applyCastlePending() {
        for i in castleTiles.indices {
            switch castleTiles[i].state {
            case .constructing(let type):
                castleTiles[i].state = .built(type: type, level: 1)
            case .upgrading(let type, let fromLevel):
                let newLevel = max(1, fromLevel) + 1
                castleTiles[i].state = .built(type: type, level: newLevel)
            case .built, .empty:
                break
            }
        }
    }

    private func recomputeCastleEconomy() {}
}

// MARK: - BuildingKind progression
extension GameStore.BuildingKind {
    var baseIncome: Int {
        switch self {
        case .mine: return 2
        case .farm: return 1
        }
    }

    var incomeGrowthPerLevel: Int {
        switch self {
        case .mine: return 2
        case .farm: return 1
        }
    }

    func incomePerDay(level: Int) -> Int {
        let lvl = max(1, level)
        return baseIncome + (lvl - 1) * incomeGrowthPerLevel
    }

    func upgradeCost(fromLevel: Int) -> Int {
        let lvl = max(1, fromLevel)
        return 10 + (lvl * lvl * 5) + (lvl * 5)
    }

    func buildCost(existingBuildings: Int) -> Int {
        return baseBuildCost + (existingBuildings * 4)
    }

    var baseBuildCost: Int {
        switch self {
        case .mine: return 20
        case .farm: return 15
        }
    }

    var maxLevel: Int {
        switch self {
        case .mine: return 5
        case .farm: return 5
        }
    }
}
