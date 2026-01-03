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

    enum BuildingKind: CaseIterable {
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

        // MVP: базовый доход за сутки (позже балансируем)
        var baseIncomePerDay: Int {
            switch self {
            case .mine: return 2
            case .farm: return 1
            }
        }

        // 024: unified income formula per level
        func incomePerDay(level: Int) -> Int {
            let lvl = max(1, level)
            switch self {
            case .farm:
                // simple: 1 per level
                return max(1, 1 * lvl)
            case .mine:
                // simple: 2 per level
                return max(1, 2 * lvl)
            }
        }
    }

    struct CastleTile: Identifiable {
        let id: Int // 0...24

        var building: BuildingKind? = nil
        var level: Int = 0
        var isUnderConstruction: Bool = false // на будущее, пока не используем

        // 023B: View-only helpers
        var isEmpty: Bool { building == nil }
        var canUpgrade: Bool { building != nil }
    }

    @Published var castleMode: CastleMode = .build
    @Published var castleTiles: [CastleTile] = (0..<25).map { CastleTile(id: $0) }

    var castleBuildingsCount: Int {
        castleTiles.filter { $0.building != nil }.count
    }

    var castleFreeTilesCount: Int {
        castleTiles.filter { $0.building == nil }.count
    }

    var castleIncomePerDay: Int {
        castleTiles.reduce(0) { acc, t in
            guard let b = t.building else { return acc }
            return acc + b.incomePerDay(level: t.level)
        }
    }

    func setCastleMode(_ mode: CastleMode) {
        castleMode = mode
        toast = "\(mode.rawValue) mode"
    }

    // Helpers for overlays
    func isCastleTileEmpty(_ index: Int) -> Bool {
        guard let idx = castleTiles.firstIndex(where: { $0.id == index }) else { return false }
        return castleTiles[idx].building == nil
    }

    func isCastleTileUpgradeable(_ index: Int) -> Bool {
        guard let idx = castleTiles.firstIndex(where: { $0.id == index }) else { return false }
        return castleTiles[idx].building != nil
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

    // Build specific kind on tile (used by Build overlay)
    func buildOnTile(index: Int, kind: BuildingKind) {
        guard let idx = castleTiles.firstIndex(where: { $0.id == index }) else { return }
        guard castleTiles[idx].building == nil else {
            toast = "Tile is not empty"
            return
        }
        castleTiles[idx].building = kind
        castleTiles[idx].level = 1
        toast = "Built \(kind.title)"
        // 024: keep header income in sync
        castleRecomputeStats()
    }

    // Upgrade tile by +1 level (used by Upgrade overlay)
    func upgradeTile(index: Int) {
        guard let idx = castleTiles.firstIndex(where: { $0.id == index }) else { return }
        guard let b = castleTiles[idx].building else { return }
        let newLevel = max(1, castleTiles[idx].level) + 1
        castleTiles[idx].level = newLevel
        toast = "Upgraded \(b.title) to Lv \(newLevel)"
        // 024: keep header income in sync
        castleRecomputeStats()
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
            pushLog(&battle, side: .enemy, "\(intent.text): no effect")
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
        // Use existing build logic
        buildOnTile(index: index, kind: candidate.kind)
        // Close and reset
        isBuildSheetPresented = false
        selectedBuildTileIndex = nil
        castleModeUI = .idle
    }

    // MARK: - Castle day tick + stats (024)
    func castleRecomputeStats() {
        // meta.incomePerDay is computed (get-only). Keep this as a hook for future aggregate recomputations.
        _ = meta.incomePerDay
    }

    func castleAdvanceDay() {
        let todayIncome = meta.incomePerDay

        meta.days += 1
        meta.gold += todayIncome

        // Recompute after possible changes (hook)
        castleRecomputeStats()
        toast = "Day +1  •  Gold +\(todayIncome)"
    }
}
