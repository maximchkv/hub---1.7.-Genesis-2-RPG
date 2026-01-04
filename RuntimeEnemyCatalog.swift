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

    let pattern: [RuntimeEnemyMove] // 3-step loop
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
            ]
        )
    ]

    static func randomV1() -> RuntimeEnemyDefinition {
        v1.randomElement() ?? v1[0]
    }
}
