import Foundation

// MARK: - Enemy v1 content model

enum EnemyRole: String, Codable {
    case damage     // базовый урон
    case defense    // защита
    case counter    // ответный приём
    case multiHit   // серии атак
}

enum EnemyPatternIntentKind: String, Codable {
    case attack
    case block
    case blockAndAttack
    case multiHitAttack
}

struct EnemyIntentStep: Identifiable, Codable, Equatable {
    let id = UUID()
    let kind: EnemyPatternIntentKind

    // Base values (X placeholders are represented by baseValue; resolution happens via resolver)
    let baseValue: Int
    let hits: Int?          // for multi-hit
    let usesWeapon: Bool    // for copy / UI (🗡️ оружием)

    // Convenience factories
    static func attack(_ x: Int) -> EnemyIntentStep {
        EnemyIntentStep(kind: .attack, baseValue: x, hits: nil, usesWeapon: false)
    }

    static func weaponAttack(_ x: Int) -> EnemyIntentStep {
        EnemyIntentStep(kind: .attack, baseValue: x, hits: nil, usesWeapon: true)
    }

    static func block(_ x: Int) -> EnemyIntentStep {
        EnemyIntentStep(kind: .block, baseValue: x, hits: nil, usesWeapon: false)
    }

    static func blockAndWeaponAttack(block: Int, attack: Int) -> EnemyIntentStep {
        // baseValue stores block; weapon attack stored in hits? no — use kind + secondary value via payload
        // To keep model simple: encode as baseValue=block, hits=attack (abusing hits as secondary value)
        EnemyIntentStep(kind: .blockAndAttack, baseValue: block, hits: attack, usesWeapon: true)
    }

    static func multiHitWeaponAttack(_ perHit: Int, hits: Int) -> EnemyIntentStep {
        EnemyIntentStep(kind: .multiHitAttack, baseValue: perHit, hits: hits, usesWeapon: true)
    }
}

struct EnemyDefinition: Identifiable, Codable, Equatable {
    let id: String

    let name: String
    let role: EnemyRole

    /// Pattern repeats indefinitely
    let pattern: [EnemyIntentStep]

    let shortDescription: String
    let loreDescription: String

    /// Optional: emoji placeholder / art key (for later images)
    let emoji: String?
}

// MARK: - Enemy v1 catalog

enum EnemyCatalog {
    /// Enemy v1 — Базовые враги (канон)
    static let v1: [EnemyDefinition] = [
        EnemyDefinition(
            id: "punisher_v1",
            name: "Каратель",
            role: .damage,
            pattern: [
                .attack(0), // X
                .attack(0), // X
                .block(0)   // X
            ],
            shortDescription: "Каратель дважды атакует, затем укрывается в защите, готовясь немедленно вернуться к нападению.",
            loreDescription: "Доктрина агрессии. Они были так обучены.",
            emoji: "🗡️"
        ),
        EnemyDefinition(
            id: "graphite_golem_v1",
            name: "Графитовый голем",
            role: .defense,
            pattern: [
                .block(0),  // X
                .block(0),  // X
                .attack(0)  // X
            ],
            shortDescription: "Голем укрепляет защиту два хода подряд, после чего прорывается сквозь защиту одной атакой.",
            loreDescription: "Привыкшие к давлению.",
            emoji: "🛡️"
        ),
        EnemyDefinition(
            id: "zesurumi_monks_v1",
            name: "Монахи Зесуруми",
            role: .counter,
            pattern: [
                .blockAndWeaponAttack(block: 0, attack: 0), // X + X (🛡️ + 🗡️ оружием)
                .blockAndWeaponAttack(block: 0, attack: 0), // X + X
                .attack(0)                                  // X
            ],
            shortDescription: "Используют защитный приём два хода подряд, затем атакуют.",
            loreDescription: "Лучшие из лучших, прошедшие подготовку в замке Ринокиро.",
            emoji: "⚔️"
        ),
        EnemyDefinition(
            id: "feiyancha_v1",
            name: "Феянча",
            role: .multiHit,
            pattern: [
                .multiHitWeaponAttack(4, hits: 2), // фикс: 4 урона оружием дважды
                .multiHitWeaponAttack(4, hits: 2), // фикс: 4 урона оружием дважды
                .attack(0)                         // X
            ],
            shortDescription: "Два раза использует двойной удар, затем наносит обычный удар.",
            loreDescription: "Без устали паря.",
            emoji: "🪽"
        )
    ]
}

// MARK: - X resolver (минимальный)

struct EnemyXResolver {
    /// Минимальная формула, чтобы X не был 0 и можно было тестить.
    /// Потом подменим на реальную шкалу (floor, difficulty, etc).
    static func resolveX(for enemyId: String, floor: Int) -> Int {
        // простая дефолтная шкала:
        // floor 1.. => 6 + floor/2
        return max(1, 6 + (floor / 2))
    }

    static func resolvedPattern(for enemy: EnemyDefinition, floor: Int) -> [EnemyIntentStep] {
        let x = resolveX(for: enemy.id, floor: floor)
        return enemy.pattern.map { step in
            switch step.kind {
            case .attack:
                // If baseValue==0 treat it as X
                if step.baseValue == 0 {
                    return step.usesWeapon ? .weaponAttack(x) : .attack(x)
                }
                return step.usesWeapon ? .weaponAttack(step.baseValue) : .attack(step.baseValue)

            case .block:
                if step.baseValue == 0 { return .block(x) }
                return .block(step.baseValue)

            case .blockAndAttack:
                // baseValue = block, hits = attack
                let b = (step.baseValue == 0) ? x : step.baseValue
                let a = ((step.hits ?? 0) == 0) ? x : (step.hits ?? x)
                return .blockAndWeaponAttack(block: b, attack: a)

            case .multiHitAttack:
                // per-hit fixed for Феянча (4), keep as-is if non-zero
                let perHit = (step.baseValue == 0) ? x : step.baseValue
                let hits = step.hits ?? 2
                return .multiHitWeaponAttack(perHit, hits: hits)
            }
        }
    }
}
