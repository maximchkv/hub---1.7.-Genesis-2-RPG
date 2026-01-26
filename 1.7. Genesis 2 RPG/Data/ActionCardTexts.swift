import Foundation

/// Тексты для карточек действий
/// 
/// ⚠️ ВАЖНО: Этот файл можно редактировать для изменения названий и описаний карт
/// Просто измените строки ниже - они автоматически применятся во всем приложении
struct ActionCardTexts {
    
    // MARK: - Система прогрессии значений карт по уровням
    // ⚠️ ВАЖНО: Это единое место для настройки всех значений карт по уровням
    
    /// Формула прогрессии: множитель для каждого уровня выше 1
    /// Измените это значение, чтобы изменить прогрессию для всех карт
    /// Пример: 1.25 = +25% за уровень, 1.3 = +30% за уровень, 1.5 = +50% за уровень
    static let levelProgressionMultiplier: Double = 1.25
    
    /// Конфигурация значений карт по уровням
    /// Для каждой карты задается базовое значение (уровень 1) и опциональные переопределения
    struct CardLevelConfig {
        let baseValue: Int  // Значение для уровня 1
        let levelOverrides: [Int: Int]?  // Переопределения для конкретных уровней [уровень: значение]
        
        /// Вычисляет значение для указанного уровня
        func value(for level: Int) -> Int {
            // Если есть переопределение для этого уровня, используем его
            if let overrides = levelOverrides, let overrideValue = overrides[level] {
                return overrideValue
            }
            
            // Если уровень 1, возвращаем базовое значение
            if level <= 1 {
                return baseValue
            }
            
            // Вычисляем по формуле прогрессии
            var v = Double(baseValue)
            for _ in 2...level {
                v = v * ActionCardTexts.levelProgressionMultiplier
            }
            return Int(v.rounded())
        }
    }
    
    /// Маппинг значений карт по уровням
    /// ⚠️ ИЗМЕНИТЕ ЭТИ ЗНАЧЕНИЯ для настройки карт
    /// 
    /// Для каждой карты можно задать:
    /// - baseValue: значение для уровня 1
    /// - levelOverrides: переопределения для конкретных уровней (опционально)
    /// 
    /// Примеры:
    /// 1. Автоматическая прогрессия: baseValue: 5, levelOverrides: nil
    ///    → Уровень 1: 5, Уровень 2: 6 (5*1.25), Уровень 3: 8 (6*1.25), и т.д.
    /// 
    /// 2. С переопределениями: baseValue: 5, levelOverrides: [2: 7, 3: 10]
    ///    → Уровень 1: 5, Уровень 2: 7 (переопределено), Уровень 3: 10 (переопределено), Уровень 4: 13 (10*1.25)
    /// 
    /// 3. Ручная настройка всех уровней: baseValue: 5, levelOverrides: [2: 7, 3: 9, 4: 12, 5: 15]
    ///    → Все значения заданы вручную, формула не используется
    static var cardLevelValues: [ActionCardKind: CardLevelConfig] {
        var configs: [ActionCardKind: CardLevelConfig] = [:]
        
        // Базовые карты
        configs[.powerStrike] = CardLevelConfig(
            baseValue: 5,
            levelOverrides: nil  // Используется формула для всех уровней
            // Пример переопределения: levelOverrides: [2: 7, 3: 10]
        )
        
        configs[.defend] = CardLevelConfig(
            baseValue: 5,
            levelOverrides: nil
        )
        
        configs[.doubleStrike] = CardLevelConfig(
            baseValue: 4,  // 80% от powerStrike (5 * 0.8 = 4)
            levelOverrides: nil
        )
        
        // counterStance использует фиксированные значения (не прогрессия)
        configs[.counterStance] = CardLevelConfig(
            baseValue: 0,  // Не используется, т.к. фиксированные значения
            levelOverrides: nil
        )
        
        // Статусные карты (не имеют прогрессии по урону/блоку)
        configs[.bleedPlus2] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        configs[.weakPlus1] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        configs[.stun1] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        
        // Синергийные карты
        configs[.bleedStrike] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        configs[.weakDefend] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        
        // Placeholders
        configs[.placeholder1] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        configs[.placeholder2] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        configs[.placeholder3] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        configs[.placeholder4] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        configs[.placeholder5] = CardLevelConfig(baseValue: 0, levelOverrides: nil)
        
        return configs
    }
    
    // MARK: - Удобные функции для получения значений карт
    
    /// Получить урон для powerStrike на указанном уровне
    static func powerStrikeDamage(level: Int) -> Int {
        return value(for: .powerStrike, level: level)
    }
    
    /// Получить блок для defend на указанном уровне
    static func defendBlock(level: Int) -> Int {
        return value(for: .defend, level: level)
    }
    
    /// Получить урон за один удар для doubleStrike на указанном уровне
    /// Вычисляется как 80% от powerStrikeDamage
    static func doubleStrikeHit(level: Int) -> Int {
        return Int((Double(powerStrikeDamage(level: level)) * 0.8).rounded())
    }
    
    /// Получить значение карты для указанного уровня
    static func value(for kind: ActionCardKind, level: Int) -> Int {
        guard let config = cardLevelValues[kind] else {
            return 0
        }
        return config.value(for: level)
    }
    
    // MARK: - Числовые значения эффектов
    // ⚠️ ИЗМЕНИТЕ ЭТИ ЗНАЧЕНИЯ, чтобы изменить числовые эффекты карт
    // Эти значения используются в описаниях автоматически
    
    // MARK: - Базовые значения урона и блока (уровень 1)
    // ⚠️ УСТАРЕЛО: Используйте value(for:level:) или удобные функции выше
    // Оставлено для обратной совместимости с описаниями
    
    /// Базовый урон карты "Мощный удар" (уровень 1)
    /// Использует систему cardLevelValues
    static var powerStrikeBaseDamage: Int {
        return powerStrikeDamage(level: 1)
    }
    
    /// Базовый блок карты "Защита" (уровень 1)
    /// Использует систему cardLevelValues
    static var defendBaseBlock: Int {
        return defendBlock(level: 1)
    }
    
    /// Базовый урон за один удар карты "Двойной удар" (уровень 1, ударов два)
    /// Использует систему cardLevelValues
    static var doubleStrikeBaseHitDamage: Int {
        return doubleStrikeHit(level: 1)
    }
    
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
        case .counterStance: return "Стойка"
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
        // Use level 1 as default for backward compatibility
        return shortDescription(for: kind, level: 1)
    }
    
    static func shortDescription(for kind: ActionCardKind, level: Int) -> String {
        switch kind {
        case .powerStrike:
            let damage = value(for: .powerStrike, level: level)
            return "Наносит урон \(damage)."
        case .defend:
            let block = value(for: .defend, level: level)
            return "Даёт блок \(block)."
        case .doubleStrike:
            let hitDamage = doubleStrikeHit(level: level)
            return "Наносит урон \(hitDamage) дважды."
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
        // Use level 1 as default for backward compatibility
        return detailedDescription(for: kind, level: 1)
    }
    
    static func detailedDescription(for kind: ActionCardKind, level: Int) -> String {
        switch kind {
        case .powerStrike:
            let damage = value(for: .powerStrike, level: level)
            return "Наносит урон \(damage) противнику (текущий уровень \(level), растёт с уровнем). Базовая атакующая карта."
        case .defend:
            let block = value(for: .defend, level: level)
            return "Даёт блок \(block) (текущий уровень \(level), растёт с уровнем), защищая от входящего урона."
        case .doubleStrike:
            let hitDamage = doubleStrikeHit(level: level)
            return "Наносит урон \(hitDamage) дважды (текущий уровень \(level), растёт с уровнем). Эффективна против блока."
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
