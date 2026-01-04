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
        case constructing(type: BuildingKind)               // will become built(level: 1) on next day tick
        case built(type: BuildingKind, level: Int)          // active building
        case upgrading(type: BuildingKind, fromLevel: Int)  // will become built(level: fromLevel+1) on next day tick

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
                return max(1, fromLevel) // while upgrade is pending — show current level
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

        // Compatibility accessors for existing UI (do not change UI files)
        var building: BuildingKind? {
            state.buildingType
        }

        // Level used by UI; 0 if empty/constructing
        var level: Int {
            switch state {
            case .built(_, let level): return max(1, level)
            case .upgrading(_, let fromLevel): return max(1, fromLevel)
            default: return 0
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
    // Sum only active built tiles. Artifact bonuses remain global via PlayerMeta.incomePerDay (as-is).
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

    // Helpers for overlays (updated to use state)
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

    // Build specific kind on tile (used by Build overlay) — legacy immediate builder
    // Kept for compatibility; prefer buildTile(tileIndex:type:) with cost and pending.
    func buildOnTile(index: Int, kind: BuildingKind) {
        guard let idx = castleTiles.firstIndex(where: { $0.id == index }) else { return }
        switch castleTiles[idx].state {
        case .empty:
            castleTiles[idx].state = .constructing(type: kind)
            toast = "Building \(kind.title) started"
        default:
            toast = "Tile is not empty"
            return
        }
        castleRecomputeStats()
    }

    // Upgrade tile by +1 level (used by Upgrade overlay) — legacy signature delegates to 027A3
    func upgradeTile(index: Int) {
        upgradeTile(tileIndex: index)
    }

    // 027A3 + 027B: Can upgrade check (gold + state + max level)
    func canUpgradeTile(tileIndex: Int) -> Bool {
        guard castleTiles.indices.contains(tileIndex) else { return false }
        let tile = castleTiles[tileIndex]
        switch tile.state {
        case .built(let type, let level):
            guard level < type.maxLevel else { return false }
            let cost = type.upgradeCost(fromLevel: level)
            return meta.gold >= cost
        default:
            return false
        }
    }

    // 027A3 + 027B: Upgrade with cost, busy checks, max level, and pending state
    func upgradeTile(tileIndex: Int) {
        guard castleTiles.indices.contains(tileIndex) else { return }

        switch castleTiles[tileIndex].state {
        case .built(let type, let level):
            // 027B: max level guard first
            guard level < type.maxLevel else {
                toast = "Max level reached"
                return
            }

            let cost = type.upgradeCost(fromLevel: level)
            guard meta.gold >= cost else {
                toast = "Not enough gold"
                return
            }

            // pay immediately on confirmation
            meta.gold -= cost

            // set pending upgrade
            castleTiles[tileIndex].state = .upgrading(type: type, fromLevel: max(1, level))

            // income should not change yet; keep hook
            castleRecomputeStats()

            toast = "Upgrade started"

        case .empty:
            toast = "Nothing to upgrade"
        case .constructing:
            toast = "Busy: constructing"
        case .upgrading:
            toast = "Busy: upgrading"
        }
    }

    // 027A4: Can build check (state + gold with scaling by existing built count)
    func canBuildTile(tileIndex: Int, type: BuildingKind) -> Bool {
        guard castleTiles.indices.contains(tileIndex) else { return false }

        let tile = castleTiles[tileIndex]
        // Only on empty tiles
        guard case .empty = tile.state else { return false }

        let builtCount = castleTiles.filter {
            if case .built = $0.state { return true }
            return false
        }.count

        let cost = type.buildCost(existingBuildings: builtCount)
        return meta.gold >= cost
    }

    // 027A4: Build with cost, busy checks, pending construction, and scaling
    func buildTile(tileIndex: Int, type: BuildingKind) {
        guard castleTiles.indices.contains(tileIndex) else { return }

        let tile = castleTiles[tileIndex]
        guard case .empty = tile.state else {
            toast = "Tile is busy"
            return
        }

        let builtCount = castleTiles.filter {
            if case .built = $0.state { return true }
            return false
        }.count

        let cost = type.buildCost(existingBuildings: builtCount)

        guard meta.gold >= cost else {
            toast = "Not enough gold"
            return
        }

        // Pay immediately
        meta.gold -= cost

        // Set pending construction
        castleTiles[tileIndex].state = .constructing(type: type)

        // Income does not change until Day Tick
        castleRecomputeStats()

        toast = "Construction started"
    }

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
        let kind: CombatLogEntry.Kind = (side == .system) ? .system : .normal
        battle.log.append(CombatLogEntry(id: UUID(), text: logText(side, message), isPlayer: side == .player, kind: kind))
    }

    // Divider marker for UI (not a visible text)
    private func pushDivider() {
        guard var b = battle else { return }
        b.log.append(CombatLogEntry(id: UUID(), text: "__DIVIDER__", isPlayer: false, kind: .separator))
        battle = b
    }

    // MARK: - Navigation
    func goToStart() { route = .start }
    func goToHub() { route = .hub }

    func goToTower() {
        route = .tower

        if run == nil {
            startRun()
        }

        if run?.roomOptions.isEmpty ?? true {
            refreshRoomOptions()
        }
    }

    func goToCastle() {
        route = .castle
        castleRoute = .main
    }

    func goToCardLibrary() { route = .cardLibrary }
    func goToChest() { route = .chest }

    // MARK: - Castle internal navigation (021B)
    func goToCastleUpgrade() {
        castleRoute = .upgrade
    }

    func goToCastleRelics() {
        castleRoute = .relics
    }

    func backToCastleMain() {
        castleRoute = .main
    }

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
        guard var r = run else { return }
        r.roomOptions = towerService.generateRoomOptions(
            nonCombatStreak: r.nonCombatStreak
        )
        run = r
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

        // Unified day tick after floor progression
        advanceDayTick()

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

    // MARK: - Day Tick (legacy, kept for compatibility in non-castle flows)
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
        newBattle.phase = .player

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

    // MARK: - Cards
    func playCard(_ card: ActionCard) {
        guard var battle = battle else { return }
        guard battle.phase == .player else { return }
        if battle.usedCardsThisTurn.contains(card.kind) { return }
        guard battle.actionPoints >= card.cost else { return }
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
            pushLog(&battle, side: .player, "\(cardTitle(card.kind)) (-\(card.cost) AP): block +\(b)")
        }

        battle.usedCardsThisTurn.insert(card.kind)
        self.battle = battle

        if battle.enemyHP <= 0 {
            winBattle()
            return
        }
    }

    func endTurn() {
        guard var b = battle else { return }
        pushLog(&b, side: .player, "End turn")
        b.phase = .enemy
        battle = b

        pushDivider()

        guard var bEnemyStart = battle else { return }
        bEnemyStart.enemyBlock = 0
        battle = bEnemyStart

        guard var b2 = battle else { return }
        performEnemyTurn(&b2)
        if self.battle == nil { return }
        battle = b2

        pushDivider()

        guard var b3 = battle else { return }
        b3.playerBlock = 0
        b3.enemyIntent = rollEnemyIntent()
        b3.actionPoints = 2
        b3.hand = drawHand()
        b3.usedCardsThisTurn.removeAll()
        b3.phase = .player
        pushLog(&b3, side: .system, "New turn: hand refreshed")
        battle = b3
    }

    private func performEnemyTurn(_ b: inout BattleState) {
        let intent = b.enemyIntent

        switch intent.kind {
        case .attack:
            b.enemyAttackedThisTurn = true
            let dmg = max(0, intent.value)
            let r = applyDamage(dmg, toHP: &b.playerHP, block: &b.playerBlock)
            pushLog(&b, side: .enemy, "Attack: dmg \(r.dealt) (blocked \(r.blocked))")
            if b.playerHP <= 0 {
                self.battle = b
                loseBattle()
                return
            }

        case .defend:
            let blockGain = max(0, intent.value)
            b.enemyBlock += blockGain
            pushLog(&b, side: .enemy, "Defend: block +\(blockGain)")

        case .counter:
            pushLog(&b, side: .enemy, "Counter")
        }
    }

    private func rollEnemyIntent() -> EnemyIntent {
        let roll = Int.random(in: 0..<100)
        if roll < 50 { return EnemyIntent(kind: .attack, value: 5) }
        if roll < 80 { return EnemyIntent(kind: .defend, value: 5) }
        return EnemyIntent(kind: .counter, value: 0)
    }

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
            pushLog(&battle, side: .enemy, "Counter")
        }

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

    // MARK: - Castle UI State
    @Published var castleModeUI: CastleUIMode = .idle
    @Published var isBuildSheetPresented: Bool = false
    @Published var isUpgradeSheetPresented: Bool = false
    @Published var selectedCastleTileIndex: Int? = nil

    // 023C: Build sheet state
    @Published var selectedBuildTileIndex: Int? = nil
    @Published var buildCandidates: [BuildCandidate] = [
        BuildCandidate(kind: .farm, title: "Farm", emoji: "🌾", incomePerDay: 1, blurb: "+1 / day"),
        BuildCandidate(kind: .mine, title: "Mine", emoji: "⛏️", incomePerDay: 2, blurb: "+2 / day")
    ]

    // MARK: - Castle UI Actions
    func setCastleMode(_ mode: CastleUIMode) {
        if castleModeUI == mode {
            castleModeUI = .idle
        } else {
            castleModeUI = mode
        }
    }

    // 023B: unified tap entry point
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

    // Backward compatibility (can be removed after View migration)
    func handleCastleTileTap(index: Int, isEmpty: Bool) {
        guard let tile = castleTiles.first(where: { $0.id == index }) else { return }
        onTileTapped(tile)
    }

    // 023B: close helpers that also reset mode to idle
    func closeBuildSheet() {
        isBuildSheetPresented = false
        castleModeUI = .idle
    }

    func closeUpgradeSheet() {
        isUpgradeSheetPresented = false
        castleModeUI = .idle
    }

    // 023C: Build sheet control
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
        // Prefer cost-aware pending build
        buildTile(tileIndex: index, type: candidate.kind)
        // Close and reset
        isBuildSheetPresented = false
        selectedBuildTileIndex = nil
        castleModeUI = .idle
    }

    // MARK: - Castle day tick + stats (026/027A1/027A2)
    func castleRecomputeStats() {
        // No-op: stats are computed via castleIncomePerDay
    }

    // Unified Day Tick per 027A2
    func advanceDayTick() {
        // 1) +1 Day
        meta.days += 1

        // 2) Income BEFORE applying pending (built only)
        let incomeBeforeApplying = castleIncomePerDay
        meta.gold += incomeBeforeApplying

        // 3) Apply pending
        applyCastlePending()

        // 4) Hook for future recomputations
        recomputeCastleEconomy()

        // Feedback
        toast = "Day +1  •  Gold +\(incomeBeforeApplying)"

        // 6) Invariants
        for tile in castleTiles {
            if case .built(_, let level) = tile.state {
                assert(level >= 1)
            }
        }
    }

    // Debug button should use the same unified tick
    func castleAdvanceDay() {
        advanceDayTick()
    }

    // Apply constructing/upgrading to become built states
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

    // No-op in this architecture; meta.incomePerDay is global baseline; castle income is computed.
    private func recomputeCastleEconomy() {
        // Keep as a hook if later you aggregate meta fields.
    }
}

// MARK: - BuildingKind income progression (027A1) + upgrade cost (027A3) + build cost (027A4) + max level (027B)
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

    // 027A3: quadratic upgrade cost
    func upgradeCost(fromLevel: Int) -> Int {
        let lvl = max(1, fromLevel)
        // L1->L2: 20, L2->L3: 35, L3->L4: 55, L4->L5: 80 ...
        return 10 + (lvl * lvl * 5) + (lvl * 5)
    }

    // 027A4: build cost with simple scaling by number of existing built buildings
    func buildCost(existingBuildings: Int) -> Int {
        // MVP: base + 4 per existing built
        return baseBuildCost + (existingBuildings * 4)
    }

    var baseBuildCost: Int {
        switch self {
        case .mine: return 20
        case .farm: return 15
        }
    }

    // 027B: max level per building type
    var maxLevel: Int {
        switch self {
        case .mine: return 5
        case .farm: return 5
        }
    }
}
