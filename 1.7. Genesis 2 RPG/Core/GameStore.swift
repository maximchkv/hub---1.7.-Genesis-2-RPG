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
    @Published var chest: ChestState? = nil
    @Published var battle: BattleState? = nil
    @Published var event: EventState? = nil

    // Reward (currently not routed, but referenced by RewardView.swift)
    @Published var reward: RewardState? = nil
    
    // Анимация дрожания портретов при получении урона
    @Published var playerShakeTrigger: Int = 0
    @Published var enemyShakeTrigger: Int = 0
    
    // Хелпер для триггера анимации дрожания
    private func triggerShake(for side: BattleSide) {
        switch side {
        case .player:
            playerShakeTrigger += 1
        case .enemy:
            enemyShakeTrigger += 1
        }
    }

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
    
    // MARK: - Run Deck Generation
    
    /// Generate starting deck for a new run
    /// 1-cost cards: 2 copies each
    /// 2-cost cards: 1 copy each
    /// All cards marked as "initial" class
    private func generateStartingDeck() -> [ActionCard] {
        var deck: [ActionCard] = []
        
        // Get all base cards
        let baseCards = ActionCardKind.allCases.filter { $0.isBaseCard }
        
        for cardKind in baseCards {
            let card = ActionCard(kind: cardKind)
            let copies: Int
            
            if card.cost == 1 {
                copies = 2
            } else if card.cost == 2 {
                copies = 1
            } else {
                copies = 1  // Fallback
            }
            
            for _ in 0..<copies {
                deck.append(ActionCard(kind: cardKind, level: 1, cardClass: "initial"))
            }
        }
        
        return deck
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

    func goToTowerEntry() {
        goToTower()
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
    }
    
    func incrementCardUsage(_ kind: ActionCardKind) {
        meta.incrementCardUsage(kind)
    }
    
    /// Get current level of a card kind from run deck (first card found)
    func getCardLevelInRunDeck(_ kind: ActionCardKind) -> Int {
        guard let run = run else { return 1 }
        return run.runDeck.first(where: { $0.kind == kind })?.level ?? 1
    }

    // MARK: - Run
    func startRun(routeToHub: Bool = true) {
        var newRun = RunState()
        
        // Generate starting deck
        newRun.runDeck = generateStartingDeck()
        
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
    
    // MARK: - Debug: Start first battle on floor 1
    func debugStartFirstBattle() {
        // Create new run
        startRun(routeToHub: false)
        
        guard var r = run, let map = r.towerMap else { return }
        
        // Find first combat room on floor 1 (leftmost by xPosition)
        let floor1Nodes = map.nodes(onFloor: 1)
        let combatNodes = floor1Nodes.filter { $0.room.kind == .combat }
        
        // Find leftmost combat node (smallest xPosition)
        guard let firstCombatNode = combatNodes.min(by: { $0.xPosition < $1.xPosition }) else {
            // Fallback: use first available combat room or first room
            if let firstCombat = floor1Nodes.first(where: { $0.room.kind == .combat }) {
                _ = r.moveToMapNode(nodeId: firstCombat.id)
                run = r
                selectRoom(firstCombat.room)
            } else if let firstRoom = floor1Nodes.first {
                _ = r.moveToMapNode(nodeId: firstRoom.id)
                run = r
                selectRoom(firstRoom.room)
            }
            return
        }
        
        // Move to the first combat node and start battle
        _ = r.moveToMapNode(nodeId: firstCombatNode.id)
        run = r
        selectRoom(firstCombatNode.room)
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
        self.chest = nil
        completeNonCombatRoomAndContinue(kind: .chest)
    }

    // MARK: - Combat core (031A/031B integrated)
    // MARK: - Значения карт по уровням (используется система из ActionCardTexts)
    
    /// Получить урон для powerStrike на указанном уровне
    private func powerStrikeDamage(level: Int) -> Int {
        return ActionCardTexts.powerStrikeDamage(level: level)
    }
    
    /// Получить блок для defend на указанном уровне
    private func defendBlock(level: Int) -> Int {
        return ActionCardTexts.defendBlock(level: level)
    }
    
    /// Получить урон за один удар для doubleStrike на указанном уровне
    private func doubleStrikeHit(level: Int) -> Int {
        return ActionCardTexts.doubleStrikeHit(level: level)
    }
    
    // Неиспользуемые функции (оставлены для совместимости)
    private func counterDamage(level: Int) -> Int { Int((Double(powerStrikeDamage(level: level)) * 0.6).rounded()) }
    private func counterBlock(level: Int) -> Int { Int((Double(defendBlock(level: level)) * 0.8).rounded()) }

    // Runtime enemy helpers (spec)
    private func enemyAttackValue() -> Int { 5 }
    private func enemyBlockValue() -> Int { 5 }

    // Counter-Stance Lv1 constants (027C-A)
    private func counterStanceBlockValue() -> Int { ActionCardTexts.counterStanceBlock }
    private func counterStanceAttackValue() -> Int { ActionCardTexts.counterStanceDamage }

    /// Выбрать конкретную карту врага для текущего шага (v2 с тегами/весами, иначе v1 fallback).
    private func pickEnemyCardForCurrentStep(_ battle: BattleState) -> ActionCardKind? {
        // v2: tagPattern + cardPool
        if !battle.enemyTagPattern.isEmpty, !battle.enemyCardPool.isEmpty {
            let index = battle.enemyPatternIndex % battle.enemyTagPattern.count
            let step = battle.enemyTagPattern[index]
            if let card = EnemyCardSelector.pickCard(from: battle.enemyCardPool, for: step) {
                return card
            }
        }

        // v1: map fixed move -> card kind
        guard !battle.enemyPattern.isEmpty else { return nil }
        let move = battle.enemyPattern[battle.enemyPatternIndex].kind
        switch move {
        case .attack: return .powerStrike
        case .defend: return .defend
        case .counterStance: return .counterStance
        case .doubleStrikeFixed4: return .doubleStrike
        }
    }

    /// Построить EnemyIntent из выбранной \"карты\" врага (включая статусные карты).
    private func enemyIntent(forCard kind: ActionCardKind, in battle: BattleState) -> EnemyIntent {
        switch kind {
        case .powerStrike:
            return EnemyIntent(kind: .attack, value: enemyAttackValue())
        case .doubleStrike:
            return EnemyIntent(kind: .doubleStrikeFixed4, value: 0)
        case .defend:
            return EnemyIntent(kind: .defend, value: enemyBlockValue())
        case .counterStance:
            return EnemyIntent(kind: .counterStance, value: 0)

        case .bleedPlus2:
            return EnemyIntent(kind: .bleed, value: ActionCardTexts.bleedPlus2Stacks)
        case .weakPlus1:
            return EnemyIntent(kind: .weak, value: ActionCardTexts.weakPlus1Stacks)
        case .stun1:
            return EnemyIntent(kind: .stun, value: ActionCardTexts.stun1Stacks)

        case .weakDefend:
            // Основной интент — защита, но эффект включает и weak (применится на ходе врага)
            return EnemyIntent(kind: .defend, value: ActionCardTexts.weakDefendBlock)

        case .bleedStrike:
            // Интент зависит от того, есть ли у игрока bleed
            let stacks = battle.stacks(.bleed, for: .player)
            if stacks > 0 {
                let base = stacks * ActionCardTexts.bleedStrikeDamageMultiplier
                return EnemyIntent(kind: .attack, value: base)
            } else {
                return EnemyIntent(kind: .bleed, value: ActionCardTexts.bleedStrikeBleedStacks)
            }

        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return EnemyIntent(kind: .attack, value: enemyAttackValue())
        }
    }

    /// Выбрать карту под текущий шаг и синхронизировать `enemySelectedCard` + `enemyIntent`.
    private func refreshEnemySelectionAndIntent(_ battle: inout BattleState) {
        let card = pickEnemyCardForCurrentStep(battle) ?? .powerStrike
        battle.enemySelectedCard = card
        battle.enemyIntent = enemyIntent(forCard: card, in: battle)
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

        // Initialize draw pile from run deck
        var drawPile = (run?.runDeck ?? []).shuffled()
        var discardPile: [ActionCard] = []
        
        // Draw initial hand of 3 cards (or as many as available)
        let cardsNeeded = 3
        let cardsToDraw = min(cardsNeeded, drawPile.count)
        let initialHand: [ActionCard]
        if cardsToDraw > 0 {
            initialHand = Array(drawPile.prefix(cardsToDraw))
            drawPile.removeFirst(cardsToDraw)
        } else {
            initialHand = []
        }

        var newBattle = BattleState(
            floor: floorLabel,
            enemyName: (kind == .boss) ? "Boss: \(enemy.name)" : (kind == .elite ? "Elite: \(enemy.name)" : enemy.name),
            playerHP: playerHP,
            playerBlock: 0,
            enemyHP: enemyHP,
            enemyBlock: 0,
            actionPoints: 3,
            hand: initialHand,
            drawPile: drawPile,
            discardPile: discardPile,
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
        newBattle.enemyTagPattern = enemy.tagPattern ?? []
        newBattle.enemyCardPool = enemy.cardPool

        // First intent (and selected card) from pattern
        refreshEnemySelectionAndIntent(&newBattle)

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
        // Pick 3 unique upgrade options with weighted probability per card:
        // - 90% probability: card costs 1 action point (weaker)
        // - 10% probability: card costs 2 action points (stronger)
        //
        // ⚠️ НАСТРОЙКА: Чтобы изменить вероятности, измените значения:
        // - probability1Cost = вероятность выбора карты за 1 очко (0.0 - 1.0)
        // - probability2Cost = вероятность выбора карты за 2 очка (0.0 - 1.0)
        // - Сумма должна быть равна 1.0
        
        let probability1Cost: Double = 0.9  // 90% вероятности для карт за 1 очко
        let probability2Cost: Double = 0.1  // 10% вероятности для карт за 2 очка
        
        // Разделяем карты по стоимости
        let pool1Cost: [ActionCardKind] = [
            .powerStrike, .defend, .bleedPlus2, .weakPlus1
        ]
        let pool2Cost: [ActionCardKind] = [
            .doubleStrike, .counterStance, .stun1,
            .bleedStrike, .weakDefend
        ]
        
        // Перемешиваем пулы для случайности
        var shuffledPool1 = pool1Cost.shuffled()
        var shuffledPool2 = pool2Cost.shuffled()
        
        var selectedCards: [ActionCardKind] = []
        var usedCards1: Set<ActionCardKind> = []
        var usedCards2: Set<ActionCardKind> = []
        
        // Выбираем 3 уникальные карты
        while selectedCards.count < 3 {
            let random = Double.random(in: 0.0...1.0)
            
            if random < probability1Cost {
                // Выбираем карту за 1 очко (90% вероятности)
                if let card = shuffledPool1.first(where: { !usedCards1.contains($0) }) {
                    selectedCards.append(card)
                    usedCards1.insert(card)
                } else {
                    // Если все карты за 1 очко использованы, выбираем из пула за 2 очка
                    if let card = shuffledPool2.first(where: { !usedCards2.contains($0) }) {
                        selectedCards.append(card)
                        usedCards2.insert(card)
                    }
                }
            } else {
                // Выбираем карту за 2 очка (10% вероятности)
                if let card = shuffledPool2.first(where: { !usedCards2.contains($0) }) {
                    selectedCards.append(card)
                    usedCards2.insert(card)
                } else {
                    // Если все карты за 2 очка использованы, выбираем из пула за 1 очко
                    if let card = shuffledPool1.first(where: { !usedCards1.contains($0) }) {
                        selectedCards.append(card)
                        usedCards1.insert(card)
                    }
                }
            }
            
            // Защита от бесконечного цикла (если карт недостаточно)
            if selectedCards.count < 3 && usedCards1.count == pool1Cost.count && usedCards2.count == pool2Cost.count {
                break
            }
        }
        
        // Перемешиваем для случайного порядка
        selectedCards.shuffle()
        
        return RewardState(options: selectedCards)
    }

    func claimReward(_ kind: ActionCardKind) {
        guard var r = run else {
            reward = nil
            route = .tower
            return
        }

        // Find first card of this kind in runDeck and upgrade it
        if let cardIndex = r.runDeck.firstIndex(where: { $0.kind == kind }) {
            let oldLevel = r.runDeck[cardIndex].level
            r.runDeck[cardIndex].level = oldLevel + 1
            
            // Also update cardLevels for backward compatibility
            r.cardLevels[kind] = oldLevel + 1
        } else {
            // Card not found in deck (shouldn't happen, but fallback)
            let old = r.cardLevels[kind] ?? 1
            r.cardLevels[kind] = old + 1
        }
        
        run = r
        
        // Unlock card in collection if first time
        unlockCard(kind)

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
        if battle.usedCardsThisTurn.contains(card.id) { return }
        guard battle.actionPoints >= card.cost else { return }
        
        // Find the card in hand (don't remove it yet - cards stay in hand until turn ends)
        guard let cardIndex = battle.hand.firstIndex(where: { $0.id == card.id }) else { return }
        let playedCard = battle.hand[cardIndex]
        
        battle.actionPoints -= card.cost

        let lvl = playedCard.level

        switch playedCard.kind {
        case .powerStrike:
            let base = powerStrikeDamage(level: lvl)
            let dmg = battle.modifiedOutgoingWeaponDamage(base, from: .player)
            let beforeHP = battle.enemyHP
            let beforeBlock = battle.enemyBlock
            battle.dealDamage(amount: dmg, to: .enemy, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.enemyHP)
            let blocked = max(0, beforeBlock - battle.enemyBlock)
            // Анимация только если был реальный урон по HP
            if dealt > 0 {
                triggerShake(for: .enemy)
            }
            pushLog(&battle, side: .player, "\(cardTitle(playedCard.kind)) (-\(playedCard.cost) AP): dmg \(dealt) (blocked \(blocked))")

        case .defend:
            let bVal = defendBlock(level: lvl)
            battle.playerBlock += bVal
            pushLog(&battle, side: .player, "\(cardTitle(playedCard.kind)) (-\(playedCard.cost) AP): block +\(bVal)")

        case .doubleStrike:
            let hit = doubleStrikeHit(level: lvl)
            let dmg1 = battle.modifiedOutgoingWeaponDamage(hit, from: .player)
            let dmg2 = battle.modifiedOutgoingWeaponDamage(hit, from: .player)
            let beforeHP = battle.enemyHP
            let beforeBlock = battle.enemyBlock
            battle.dealDamage(amount: dmg1, to: .enemy, isWeaponDamage: true)
            let afterFirstHP = battle.enemyHP
            battle.dealDamage(amount: dmg2, to: .enemy, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.enemyHP)
            let blocked = max(0, beforeBlock - battle.enemyBlock)
            // Анимация только если был реальный урон по HP
            if max(0, beforeHP - afterFirstHP) > 0 {
                triggerShake(for: .enemy) // Первый удар
            }
            if max(0, afterFirstHP - battle.enemyHP) > 0 {
                triggerShake(for: .enemy) // Второй удар
            }
            pushLog(&battle, side: .player, "\(cardTitle(playedCard.kind)) (-\(playedCard.cost) AP): dmg \(dealt) (blocked \(blocked))")

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
            // Анимация только если был реальный урон по HP
            if dealt > 0 {
                triggerShake(for: .enemy)
            }
            pushLog(&battle, side: .player, "\(cardTitle(playedCard.kind)) (-\(playedCard.cost) AP): block +\(bVal), dmg \(dealt) (blocked \(blocked))")

        // 031B: Status cards
        case .bleedPlus2:
            battle.addStatus(.bleed, stacks: ActionCardTexts.bleedPlus2Stacks, to: .enemy)
            pushLog(&battle, side: .player, "Player uses Кровоток → Enemy: Кровоток +\(ActionCardTexts.bleedPlus2Stacks)")

        case .weakPlus1:
            battle.addStatus(.weak, stacks: ActionCardTexts.weakPlus1Stacks, to: .enemy)
            pushLog(&battle, side: .player, "Player uses Ослабить → Enemy: Слабость +\(ActionCardTexts.weakPlus1Stacks)")

        case .stun1:
            battle.addStatus(.stun, stacks: ActionCardTexts.stun1Stacks, to: .enemy)
            pushLog(&battle, side: .player, "Player uses Оглушить → Enemy: Оглушение \(ActionCardTexts.stun1Stacks)")
        
        // Синергийные карты
        case .bleedStrike:
            let enemyBleedStacks = battle.enemyStatuses.first(where: { $0.type == .bleed })?.stacks ?? 0
            if enemyBleedStacks > 0 {
                // Если у врага есть кровотечение: урон = стаки × множитель
                // Урон проходит через modifiedOutgoingWeaponDamage для учета слабости
                let baseDmg = enemyBleedStacks * ActionCardTexts.bleedStrikeDamageMultiplier
                let dmg = battle.modifiedOutgoingWeaponDamage(baseDmg, from: .player)
                let beforeHP = battle.enemyHP
                let beforeBlock = battle.enemyBlock
                battle.dealDamage(amount: dmg, to: .enemy, isWeaponDamage: true)
                let dealt = max(0, beforeHP - battle.enemyHP)
                let blocked = max(0, beforeBlock - battle.enemyBlock)
                // Анимация только если был реальный урон по HP
                if dealt > 0 {
                    triggerShake(for: .enemy)
                }
                pushLog(&battle, side: .player, "\(cardTitle(playedCard.kind)) (-\(playedCard.cost) AP): dmg \(dealt) (blocked \(blocked), от кровотечения ×\(enemyBleedStacks))")
            } else {
                // Если у врага нет кровотечения: наложить Bleed
                battle.addStatus(.bleed, stacks: ActionCardTexts.bleedStrikeBleedStacks, to: .enemy)
                pushLog(&battle, side: .player, "\(cardTitle(playedCard.kind)) (-\(playedCard.cost) AP): Кровоток +\(ActionCardTexts.bleedStrikeBleedStacks)")
            }
        
        case .weakDefend:
            battle.addStatus(.weak, stacks: ActionCardTexts.weakDefendWeakStacks, to: .enemy)
            battle.playerBlock += ActionCardTexts.weakDefendBlock
            pushLog(&battle, side: .player, "\(cardTitle(playedCard.kind)) (-\(playedCard.cost) AP): Слабость +\(ActionCardTexts.weakDefendWeakStacks) врагу, блок +\(ActionCardTexts.weakDefendBlock)")
            
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            // Placeholders should never be playable
            break
        }

        battle.usedCardsThisTurn.insert(playedCard.id)
        self.battle = battle
        
        // Track card usage in collection
        incrementCardUsage(playedCard.kind)

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
        // Триггер анимации для урона от кровотечения
        if out.damageDealtToEnemy > 0 {
            triggerShake(for: .enemy)
        }
        if out.damageDealtToPlayer > 0 {
            triggerShake(for: .player)
        }
        // Важно: сохраняем изменения статусов сразу после startOfTurn
        self.battle = b
        b = self.battle!

        // Enemy phase: per spec (only if not stunned)
        if !out.didSkipTurn {
            pushSeparator()
            performEnemyTurn()
            if let after = self.battle { b = after }
            pushSeparator()
        }
        
        // Паттерн продвигается всегда, даже если ход пропущен (оглушение)
        cycleEnemyIntent()
        if let after = self.battle { b = after }

        // 031A: Start of player turn (statuses)
        out = b.startOfTurn(for: .player)
        for line in out.logLines {
            b.log.append(CombatLogEntry.system(line))
        }
        // Триггер анимации для урона от кровотечения
        if out.damageDealtToPlayer > 0 {
            triggerShake(for: .player)
        }
        if out.damageDealtToEnemy > 0 {
            triggerShake(for: .enemy)
        }

        // Prepare next player turn
        b.playerBlock = 0
        // enemyBlock will be reset at the start of enemy turn (not here)
        b.actionPoints = 3
        
        // Move all cards from hand to discard pile
        b.discardPile.append(contentsOf: b.hand)
        b.hand = []
        
        // If draw pile doesn't have enough cards (need 3), refresh from discard pile
        let cardsNeeded = 3
        if b.drawPile.count < cardsNeeded && !b.discardPile.isEmpty {
            // Shuffle discard pile and add to draw pile
            b.drawPile.append(contentsOf: b.discardPile.shuffled())
            b.discardPile = []
        }
        
        // Draw 3 cards from draw pile (or as many as available)
        let cardsToDraw = min(cardsNeeded, b.drawPile.count)
        if cardsToDraw > 0 {
            let drawn = Array(b.drawPile.prefix(cardsToDraw))
            b.drawPile.removeFirst(cardsToDraw)
            b.hand = drawn
        } else {
            b.hand = []
        }
        
        b.usedCardsThisTurn.removeAll()
        b.phase = .player
        pushLog(&b, side: .system, "New turn: hand refreshed")
        battle = b
    }

    private func performEnemyTurn() {
        guard var battle = battle else { return }
        
        // Reset enemy block at the start of enemy turn (after player's turn)
        battle.enemyBlock = 0

        let card = battle.enemySelectedCard ?? pickEnemyCardForCurrentStep(battle) ?? .powerStrike

        switch card {
        case .powerStrike:
            let base = enemyAttackValue()
            let dmg = battle.modifiedOutgoingWeaponDamage(base, from: .enemy)
            let beforeHP = battle.playerHP
            let beforeBlock = battle.playerBlock
            battle.dealDamage(amount: dmg, to: .player, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.playerHP)
            let blocked = max(0, beforeBlock - battle.playerBlock)
            if dealt > 0 { triggerShake(for: .player) }
            pushLog(&battle, side: .enemy, "Power Strike: dmg \(dealt) (blocked \(blocked))")

        case .defend:
            let block = enemyBlockValue()
            battle.enemyBlock += block
            pushLog(&battle, side: .enemy, "Defend: block +\(block)")

        case .doubleStrike:
            let base = 4
            let dmg1 = battle.modifiedOutgoingWeaponDamage(base, from: .enemy)
            let dmg2 = battle.modifiedOutgoingWeaponDamage(base, from: .enemy)
            let beforeHP = battle.playerHP
            let beforeBlock = battle.playerBlock
            battle.dealDamage(amount: dmg1, to: .player, isWeaponDamage: true)
            let afterFirstHP = battle.playerHP
            battle.dealDamage(amount: dmg2, to: .player, isWeaponDamage: true)
            let dealt = max(0, beforeHP - battle.playerHP)
            let blocked = max(0, beforeBlock - battle.playerBlock)
            if max(0, beforeHP - afterFirstHP) > 0 { triggerShake(for: .player) }
            if max(0, afterFirstHP - battle.playerHP) > 0 { triggerShake(for: .player) }
            pushLog(&battle, side: .enemy, "Double Strike: dmg \(dealt) (blocked \(blocked))")

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
            if dealt > 0 { triggerShake(for: .player) }
            pushLog(&battle, side: .enemy, "Counter Stance: block +\(bVal), dmg \(dealt) (blocked \(blocked))")

        case .bleedPlus2:
            battle.addStatus(.bleed, stacks: ActionCardTexts.bleedPlus2Stacks, to: .player)
            pushLog(&battle, side: .enemy, "Bleed: +\(ActionCardTexts.bleedPlus2Stacks)")

        case .weakPlus1:
            battle.addStatus(.weak, stacks: ActionCardTexts.weakPlus1Stacks, to: .player)
            pushLog(&battle, side: .enemy, "Weak: +\(ActionCardTexts.weakPlus1Stacks)")

        case .stun1:
            battle.addStatus(.stun, stacks: ActionCardTexts.stun1Stacks, to: .player)
            pushLog(&battle, side: .enemy, "Stun: +\(ActionCardTexts.stun1Stacks)")

        case .weakDefend:
            battle.enemyBlock += ActionCardTexts.weakDefendBlock
            battle.addStatus(.weak, stacks: ActionCardTexts.weakDefendWeakStacks, to: .player)
            pushLog(&battle, side: .enemy, "Weak Defend: block +\(ActionCardTexts.weakDefendBlock), weak +\(ActionCardTexts.weakDefendWeakStacks)")

        case .bleedStrike:
            let stacks = battle.stacks(.bleed, for: .player)
            if stacks > 0 {
                let base = stacks * ActionCardTexts.bleedStrikeDamageMultiplier
                let dmg = battle.modifiedOutgoingWeaponDamage(base, from: .enemy)
                let beforeHP = battle.playerHP
                let beforeBlock = battle.playerBlock
                battle.dealDamage(amount: dmg, to: .player, isWeaponDamage: true)
                let dealt = max(0, beforeHP - battle.playerHP)
                let blocked = max(0, beforeBlock - battle.playerBlock)
                if dealt > 0 { triggerShake(for: .player) }
                pushLog(&battle, side: .enemy, "Bleed Strike: dmg \(dealt) (blocked \(blocked))")
            } else {
                battle.addStatus(.bleed, stacks: ActionCardTexts.bleedStrikeBleedStacks, to: .player)
                pushLog(&battle, side: .enemy, "Bleed Strike: bleed +\(ActionCardTexts.bleedStrikeBleedStacks)")
            }

        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            pushLog(&battle, side: .enemy, "Enemy does nothing")
        }

        if battle.playerHP <= 0 {
            self.battle = battle
            loseBattle()
            return
        }

        self.battle = battle
    }

    func cycleEnemyIntent() {
        guard var battle = battle else { return }
        // Сохраняем текущие статусы перед изменением интента
        let savedPlayerStatuses = battle.playerStatuses
        let savedEnemyStatuses = battle.enemyStatuses
        battle.advanceEnemyPattern()
        refreshEnemySelectionAndIntent(&battle)
        // Восстанавливаем статусы (на случай если они были потеряны)
        battle.playerStatuses = savedPlayerStatuses
        battle.enemyStatuses = savedEnemyStatuses
        self.battle = battle
    }

    private func cardTitle(_ kind: ActionCardKind) -> String {
        ActionCardTexts.logTitle(for: kind)
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
