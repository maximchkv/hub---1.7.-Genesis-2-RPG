struct BattleState {
    enum Phase: String, Codable, Hashable {
        case player
        case enemy
    }

    var floor: Int
    var enemyName: String

    // Базовые статы боя (011A/011B)
    var playerHP: Int = 20
    var playerBlock: Int = 0

    var enemyHP: Int = 20
    var enemyBlock: Int = 0

    // Runtime enemy (pattern-based)
    var enemyRuntimeKind: RuntimeEnemyKind = .punisher
    var enemyRole: String = ""
    var enemyPattern: [RuntimeEnemyMove] = []
    var enemyPatternIndex: Int = 0

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

    // 018A: текущая фаза хода
    var phase: Phase = .player

    // 031A: Status system storage + skip flags
    var playerStatuses: [StatusInstance] = []
    var enemyStatuses: [StatusInstance] = []
    var playerSkipTurn: Bool = false
    var enemySkipTurn: Bool = false

    mutating func advanceEnemyPattern() {
        guard !enemyPattern.isEmpty else { return }
        enemyPatternIndex = (enemyPatternIndex + 1) % enemyPattern.count
    }

    // MARK: - 031A: Status utilities

    mutating func addStatus(_ type: StatusType, stacks add: Int, to side: BattleSide) {
        guard add > 0 else { return }

        switch side {
        case .player:
            if let idx = playerStatuses.firstIndex(where: { $0.type == type }) {
                playerStatuses[idx].stacks += add
            } else {
                playerStatuses.append(StatusInstance(type: type, stacks: add))
            }
        case .enemy:
            if let idx = enemyStatuses.firstIndex(where: { $0.type == type }) {
                enemyStatuses[idx].stacks += add
            } else {
                enemyStatuses.append(StatusInstance(type: type, stacks: add))
            }
        }
    }

    mutating func startOfTurn(for side: BattleSide) -> TurnStartOutcome {
        var outcome = TurnStartOutcome()

        // 1) Bleed applies first (Block -> HP)
        applyBleedIfNeeded(for: side, outcome: &outcome)

        // 2) Stun check
        let stunned = decrementStunIfNeeded(for: side, outcome: &outcome)
        if stunned {
            setSkipTurn(true, for: side)
            outcome.didSkipTurn = true
            // 2b) Other durations tick
            decrementDurations(for: side, outcome: &outcome)
            cleanupStatuses(for: side)
            return outcome
        } else {
            setSkipTurn(false, for: side)
        }

        // 3) Duration statuses tick down (Weak/Vulnerable)
        decrementDurations(for: side, outcome: &outcome)

        // 4) Cleanup
        cleanupStatuses(for: side)

        return outcome
    }

    private mutating func applyBleedIfNeeded(for side: BattleSide, outcome: inout TurnStartOutcome) {
        let stacks = getStacks(.bleed, for: side)
        guard stacks > 0 else { return }

        // Status damage: NOT weapon, passes Block first
        dealDamage(amount: stacks, to: side, isWeaponDamage: false)
        outcome.logLines.append("\(side == .player ? "Player" : "Enemy") suffers Bleed (\(stacks)).")

        // Decay by 3
        addOrSetStacks(.bleed, for: side, newStacks: max(0, stacks - 3))
    }

    private mutating func decrementStunIfNeeded(for side: BattleSide, outcome: inout TurnStartOutcome) -> Bool {
        let stacks = getStacks(.stun, for: side)
        guard stacks > 0 else { return false }

        outcome.logLines.append("\(side == .player ? "Player" : "Enemy") is Stunned and skips the turn.")
        addOrSetStacks(.stun, for: side, newStacks: max(0, stacks - 1))
        return true
    }

    private mutating func decrementDurations(for side: BattleSide, outcome: inout TurnStartOutcome) {
        // Weak
        let weak = getStacks(.weak, for: side)
        if weak > 0 {
            addOrSetStacks(.weak, for: side, newStacks: max(0, weak - 1))
        }

        // Vulnerable
        let vuln = getStacks(.vulnerable, for: side)
        if vuln > 0 {
            addOrSetStacks(.vulnerable, for: side, newStacks: max(0, vuln - 1))
        }
    }

    private mutating func cleanupStatuses(for side: BattleSide) {
        switch side {
        case .player:
            playerStatuses.removeAll { $0.stacks <= 0 }
        case .enemy:
            enemyStatuses.removeAll { $0.stacks <= 0 }
        }
    }

    private mutating func setSkipTurn(_ value: Bool, for side: BattleSide) {
        switch side {
        case .player: playerSkipTurn = value
        case .enemy: enemySkipTurn = value
        }
    }

    private func getStacks(_ type: StatusType, for side: BattleSide) -> Int {
        switch side {
        case .player:
            return playerStatuses.first(where: { $0.type == type })?.stacks ?? 0
        case .enemy:
            return enemyStatuses.first(where: { $0.type == type })?.stacks ?? 0
        }
    }

    private mutating func addOrSetStacks(_ type: StatusType, for side: BattleSide, newStacks: Int) {
        switch side {
        case .player:
            if let idx = playerStatuses.firstIndex(where: { $0.type == type }) {
                playerStatuses[idx].stacks = newStacks
            } else if newStacks > 0 {
                playerStatuses.append(StatusInstance(type: type, stacks: newStacks))
            }
        case .enemy:
            if let idx = enemyStatuses.firstIndex(where: { $0.type == type }) {
                enemyStatuses[idx].stacks = newStacks
            } else if newStacks > 0 {
                enemyStatuses.append(StatusInstance(type: type, stacks: newStacks))
            }
        }
    }

    // MARK: - 031A: Unified damage helpers

    mutating func dealDamage(amount: Int, to side: BattleSide, isWeaponDamage: Bool) {
        guard amount > 0 else { return }

        let final = modifiedDamage(amount: amount, to: side, isWeaponDamage: isWeaponDamage)

        switch side {
        case .player:
            let absorbed = min(playerBlock, final)
            playerBlock -= absorbed
            let rest = final - absorbed
            if rest > 0 { playerHP = max(0, playerHP - rest) }
        case .enemy:
            let absorbed = min(enemyBlock, final)
            enemyBlock -= absorbed
            let rest = final - absorbed
            if rest > 0 { enemyHP = max(0, enemyHP - rest) }
        }
    }

    private func modifiedDamage(amount: Int, to target: BattleSide, isWeaponDamage: Bool) -> Int {
        guard isWeaponDamage else { return amount }

        var result = amount
        // Incoming Vulnerable on target
        if getStacks(.vulnerable, for: target) > 0 {
            result = Int((Double(result) * 1.25).rounded())
        }
        return max(0, result)
    }

    func modifiedOutgoingWeaponDamage(_ base: Int, from attacker: BattleSide) -> Int {
        guard base > 0 else { return 0 }
        var result = base
        // Outgoing Weak on attacker
        if getStacks(.weak, for: attacker) > 0 {
            result = Int((Double(result) * 0.75).rounded())
        }
        return max(0, result)
    }
}
