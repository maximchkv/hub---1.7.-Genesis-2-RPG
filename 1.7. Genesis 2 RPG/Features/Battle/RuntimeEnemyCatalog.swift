import Foundation

enum RuntimeEnemyKind: String, Codable, CaseIterable {
    case punisher
    case graphiteGolem
    case zesurumiMonks
    case feyanchа
}

enum RuntimeEnemyMoveKind: String, Codable {
    case attack
    case defend
    case counterStance      // block + attack
    case doubleStrikeFixed4 // 2 hits x 4
}

struct RuntimeEnemyMove: Codable, Identifiable, Equatable {
    let id = UUID()
    let kind: RuntimeEnemyMoveKind
}

struct RuntimeEnemyDefinition: Codable, Identifiable, Equatable {
    let id = UUID()
    let kind: RuntimeEnemyKind

    let name: String
    let role: String

    let shortDescription: String
    let loreDescription: String

    /// Старый v1-паттерн по фиксированным ходам (attack/defend/...)
    let pattern: [RuntimeEnemyMove] // 3-step loop

    /// Пул типов карт, из которых враг выбирает ходы (v2)
    var cardPool: [ActionCardKind] = []

    /// Паттерн по шагам, определённым через теги карт (v2)
    var tagPattern: [EnemyPatternStepByTag]? = nil
}

struct RuntimeEnemyCatalog {
    static let v1: [RuntimeEnemyDefinition] = [
        RuntimeEnemyDefinition(
            kind: .punisher,
            name: "Каратель",
            role: "базовый урон",
            shortDescription: "Каратель дважды атакует, затем укрывается в защите, готовясь немедленно вернуться к нападению.",
            loreDescription: "Доктрина агрессии. Они были так обучены.",
            pattern: [
                RuntimeEnemyMove(kind: .attack),
                RuntimeEnemyMove(kind: .attack),
                RuntimeEnemyMove(kind: .defend)
            ],
            cardPool: [
                .powerStrike,
                .doubleStrike,
                .defend,
                .counterStance
            ],
            tagPattern: [
                EnemyPatternStepByTag(
                    index: 0,
                    requiredTags: [.attacking],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .powerStrike, weight: 80),
                        EnemyCardCandidate(kind: .doubleStrike, weight: 20)
                    ]
                ),
                EnemyPatternStepByTag(
                    index: 1,
                    requiredTags: [.attacking],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .powerStrike, weight: 50),
                        EnemyCardCandidate(kind: .doubleStrike, weight: 50)
                    ]
                ),
                EnemyPatternStepByTag(
                    index: 2,
                    requiredTags: [.defending],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .defend, weight: 70),
                        EnemyCardCandidate(kind: .counterStance, weight: 30)
                    ]
                )
            ]
        ),
        RuntimeEnemyDefinition(
            kind: .graphiteGolem,
            name: "Графитовый голем",
            role: "защита",
            shortDescription: "Голем укрепляет защиту два хода подряд, после чего прорывается сквозь защиту одной атакой.",
            loreDescription: "Привыкшие к давлению.",
            pattern: [
                RuntimeEnemyMove(kind: .defend),
                RuntimeEnemyMove(kind: .defend),
                RuntimeEnemyMove(kind: .attack)
            ],
            cardPool: [
                .defend,
                .weakDefend,
                .powerStrike,
                .bleedPlus2
            ],
            tagPattern: [
                EnemyPatternStepByTag(
                    index: 0,
                    requiredTags: [.defending],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .defend, weight: 80),
                        EnemyCardCandidate(kind: .weakDefend, weight: 20)
                    ]
                ),
                EnemyPatternStepByTag(
                    index: 1,
                    requiredTags: [.defending],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .defend, weight: 80),
                        EnemyCardCandidate(kind: .weakDefend, weight: 20)
                    ]
                ),
                EnemyPatternStepByTag(
                    index: 2,
                    requiredTags: [],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .powerStrike, weight: 70),
                        EnemyCardCandidate(kind: .bleedPlus2, weight: 30)
                    ]
                )
            ]
        ),
        RuntimeEnemyDefinition(
            kind: .zesurumiMonks,
            name: "Монахи Зесуруми",
            role: "ответный приём",
            shortDescription: "Используют защитный приём два хода подряд, затем атакуют.",
            loreDescription: "Лучшие из лучших, прошедшие подготовку в замке Ринокиро.",
            pattern: [
                RuntimeEnemyMove(kind: .counterStance),
                RuntimeEnemyMove(kind: .counterStance),
                RuntimeEnemyMove(kind: .attack)
            ],
            cardPool: [
                .counterStance,
                .defend,
                .powerStrike,
                .stun1
            ],
            tagPattern: [
                EnemyPatternStepByTag(
                    index: 0,
                    requiredTags: [],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .counterStance, weight: 70),
                        EnemyCardCandidate(kind: .defend, weight: 30)
                    ]
                ),
                EnemyPatternStepByTag(
                    index: 1,
                    requiredTags: [],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .counterStance, weight: 70),
                        EnemyCardCandidate(kind: .defend, weight: 30)
                    ]
                ),
                EnemyPatternStepByTag(
                    index: 2,
                    requiredTags: [],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .powerStrike, weight: 60),
                        EnemyCardCandidate(kind: .stun1, weight: 40)
                    ]
                )
            ]
        ),
        RuntimeEnemyDefinition(
            kind: .feyanchа,
            name: "Феянча",
            role: "серии атак",
            shortDescription: "Два раза использует двойной удар, затем наносит обычный удар.",
            loreDescription: "Без устали паря.",
            pattern: [
                RuntimeEnemyMove(kind: .doubleStrikeFixed4),
                RuntimeEnemyMove(kind: .doubleStrikeFixed4),
                RuntimeEnemyMove(kind: .attack)
            ],
            cardPool: [
                .doubleStrike,
                .powerStrike,
                .bleedPlus2
            ],
            tagPattern: [
                EnemyPatternStepByTag(
                    index: 0,
                    requiredTags: [],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .doubleStrike, weight: 80),
                        EnemyCardCandidate(kind: .powerStrike, weight: 20)
                    ]
                ),
                EnemyPatternStepByTag(
                    index: 1,
                    requiredTags: [],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .doubleStrike, weight: 80),
                        EnemyCardCandidate(kind: .powerStrike, weight: 20)
                    ]
                ),
                EnemyPatternStepByTag(
                    index: 2,
                    requiredTags: [],
                    preferredTags: [],
                    minTier: nil,
                    maxTier: nil,
                    candidates: [
                        EnemyCardCandidate(kind: .powerStrike, weight: 60),
                        EnemyCardCandidate(kind: .bleedPlus2, weight: 40)
                    ]
                )
            ]
        )
    ]

    static func randomV1() -> RuntimeEnemyDefinition {
        v1.randomElement() ?? v1[0]
    }
}
