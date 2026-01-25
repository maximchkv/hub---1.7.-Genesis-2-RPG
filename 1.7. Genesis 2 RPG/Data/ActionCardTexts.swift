import Foundation

/// Тексты для карточек действий
/// 
/// ⚠️ ВАЖНО: Этот файл можно редактировать для изменения названий и описаний карт
/// Просто измените строки ниже - они автоматически применятся во всем приложении
struct ActionCardTexts {
    
    // MARK: - Числовые значения эффектов
    // ⚠️ ИЗМЕНИТЕ ЭТИ ЗНАЧЕНИЯ, чтобы изменить числовые эффекты карт
    // Эти значения используются в описаниях автоматически
    
    // MARK: - Базовые значения урона и блока (уровень 1)
    // Базовые значения для карт, которые растут с уровнем
    
    /// Базовый урон карты "Мощный удар" (уровень 1)
    static let powerStrikeBaseDamage: Int = 5
    
    /// Базовый блок карты "Защита" (уровень 1)
    static let defendBaseBlock: Int = 5
    
    /// Базовый урон за один удар карты "Двойной удар" (уровень 1, ударов два)
    /// Вычисляется как powerStrikeBaseDamage * 0.8 (округлено)
    static let doubleStrikeBaseHitDamage: Int = 4
    
    // MARK: - Фиксированные значения (не зависят от уровня)
    
    /// Блок карты "Контратака" (фиксированное значение)
    static let counterStanceBlock: Int = 4
    
    /// Урон карты "Контратака" (фиксированное значение)
    static let counterStanceDamage: Int = 3
    
    // MARK: - Статусные эффекты
    
    /// Количество стаков Кровотока, накладываемое картой bleedPlus2
    static let bleedPlus2Stacks: Int = 2
    
    /// Количество стаков Слабости, накладываемое картой weakPlus1
    static let weakPlus1Stacks: Int = 1
    
    /// Количество стаков Оглушения, накладываемое картой stun1
    static let stun1Stacks: Int = 1
    
    /// Количество стаков Кровотока, накладываемое картой bleedStrike (если у врага нет кровотечения)
    static let bleedStrikeBleedStacks: Int = 2
    
    /// Множитель урона для bleedStrike (урон = стаки × этот множитель)
    static let bleedStrikeDamageMultiplier: Int = 3
    
    /// Количество стаков Слабости, накладываемое картой weakDefend
    static let weakDefendWeakStacks: Int = 1
    
    /// Количество блока, даваемое картой weakDefend
    static let weakDefendBlock: Int = 4
    
    // MARK: - Названия карт
    // Измените эти строки, чтобы изменить названия карт в игре
    
    static func title(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "Мощный удар"
        case .defend: return "Защита"
        case .doubleStrike: return "Двойной удар"
        case .counterStance: return "Контратака"
        case .bleedPlus2: return "Кровоток"
        case .weakPlus1: return "Ослабить"
        case .stun1: return "Оглушить"
        case .bleedStrike: return "Кровавый удар"
        case .weakDefend: return "Ослабляющий щит"
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "???"
        }
    }
    
    // MARK: - Короткие описания (для карточек в бою)
    // Измените эти строки для изменения коротких описаний на карточках
    // Числовые значения берутся из констант выше автоматически
    
    static func shortDescription(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "Наносит урон \(powerStrikeBaseDamage)."
        case .defend: return "Даёт блок \(defendBaseBlock)."
        case .doubleStrike: return "Наносит урон \(doubleStrikeBaseHitDamage) дважды."
        case .counterStance: return "Блок \(counterStanceBlock), урон \(counterStanceDamage)."
        case .bleedPlus2: return "Накладывает Кровоток +\(bleedPlus2Stacks)."
        case .weakPlus1: return "Накладывает Слабость +\(weakPlus1Stacks)."
        case .stun1: return "Накладывает Оглушение \(stun1Stacks)."
        case .bleedStrike: return "Если у врага Кровоток: урон = стаки × \(bleedStrikeDamageMultiplier). Иначе: Кровоток +\(bleedStrikeBleedStacks)."
        case .weakDefend: return "Слабость +\(weakDefendWeakStacks) врагу. Блок +\(weakDefendBlock)."
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "Будущая карта"
        }
    }
    
    // MARK: - Подробные описания (для детального просмотра)
    // Измените эти строки для изменения подробных описаний в CardDetailView
    // Числовые значения берутся из констант выше автоматически
    
    static func detailedDescription(for kind: ActionCardKind) -> String {
        switch kind {
        case .powerStrike: return "Наносит урон \(powerStrikeBaseDamage) противнику (базовое значение, растёт с уровнем). Базовая атакующая карта."
        case .defend: return "Даёт блок \(defendBaseBlock) (базовое значение, растёт с уровнем), защищая от входящего урона."
        case .doubleStrike: return "Наносит урон \(doubleStrikeBaseHitDamage) дважды (базовое значение за удар, растёт с уровнем). Эффективна против блока."
        case .counterStance: return "Даёт блок \(counterStanceBlock) и наносит урон \(counterStanceDamage) одновременно."
        case .bleedPlus2: return "Накладывает Кровоток +\(bleedPlus2Stacks) на противника. Кровоток наносит урон в начале каждого хода."
        case .weakPlus1: return "Накладывает Слабость +\(weakPlus1Stacks) на противника. Слабость уменьшает наносимый урон."
        case .stun1: return "Накладывает Оглушение \(stun1Stacks) на противника. Оглушенный пропускает следующий ход."
        case .bleedStrike: return "Если у противника есть Кровоток: наносит урон равный стакам Кровотока × \(bleedStrikeDamageMultiplier). Если Кровотока нет: накладывает Кровоток +\(bleedStrikeBleedStacks). Синергийная карта для тактики кровотечения."
        case .weakDefend: return "Накладывает Слабость +\(weakDefendWeakStacks) на противника и даёт Блок +\(weakDefendBlock). Комбинирует контроль и защиту."
        case .placeholder1, .placeholder2, .placeholder3, .placeholder4, .placeholder5:
            return "Эта карта появится в будущих обновлениях. Продолжение следует..."
        }
    }
    
    // MARK: - Названия для логов (используется в GameStore)
    // Измените эти строки для изменения названий в логах боя
    
    static func logTitle(for kind: ActionCardKind) -> String {
        // По умолчанию используем обычное название
        return title(for: kind)
    }
    
    // MARK: - Устаревшие методы (для обратной совместимости)
    
    @available(*, deprecated, message: "Используйте shortDescription(for:)")
    static func description(for kind: ActionCardKind) -> String {
        return shortDescription(for: kind)
    }
}
