================================================================================
                    TOWERVIEW LAYOUT PATTERNS — GENESIS 2 RPG
================================================================================

Детальное описание паттернов layout'а, использованных в TowerView для реализации
динамической тактической секции с автоматическим расчетом высоты на основе safe area.

Цель: задокументировать решения для будущих экранов с похожими требованиями.


================================================================================
1. АРХИТЕКТУРА LAYOUT'А
================================================================================

TowerView использует многоуровневую структуру для управления динамической высотой:

1. **GeometryReader** на уровне экрана для измерения размеров и safe area
2. **ScrollView** с VStack для прокручиваемого контента
3. **PreferenceKey** для передачи позиции тактической секции
4. **GeometryReader** внутри тактической секции для расчета доступной высоты
5. **HStack** со Spacer'ами для центрирования GeometryReader


================================================================================
2. ПРОБЛЕМА И РЕШЕНИЕ
================================================================================

**Проблема:**
- Тактическая секция (желтый блок) должна доходить до нижней границы safe area
- Внутри секции 3 карточки должны равномерно распределяться по высоте
- Карточки не должны выходить за пределы safe area
- Layout должен адаптироваться при изменении размера экрана

**Решение:**
- Использование `.global` координат для измерения реальной позиции блока
- Динамический расчет высоты: `screenHeight - safeAreaBottom - standardPadding - blockTopY`
- Равномерное распределение карточек: `cardHeight = (availableHeight - totalSpacing) / cardCount`


================================================================================
3. PATTERN: PreferenceKey для позиции секции
================================================================================

**Когда использовать:**
Когда нужно передать позицию/размер дочернего элемента к родительскому для динамических расчетов.

**Реализация:**

```swift
// 1. Определяем PreferenceKey
private struct TacticalTopYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 2. В родительской вьюхе храним позицию в @State
@State private var tacticalTopY: CGFloat = 0

// 3. В дочерней вьюхе отправляем позицию
tacticalSection(...)
    .background(
        GeometryReader { proxy in
            Color.clear.preference(key: TacticalTopYKey.self, value: proxy.frame(in: .global).minY)
        }
    )

// 4. В родительской вьюхе получаем позицию
.onPreferenceChange(TacticalTopYKey.self) { value in
    tacticalTopY = value
}
```

**Преимущества:**
- Автоматическое отслеживание изменений позиции
- Не требует явных callback'ов или делегатов
- SwiftUI нативно поддерживает этот паттерн


================================================================================
4. PATTERN: GeometryReader в ScrollView с центрированием
================================================================================

**Проблема:** GeometryReader внутри ScrollView расширяется на всю ширину и теряет центрирование.

**Решение:** Обернуть GeometryReader в HStack со Spacer'ами.

```swift
// ❌ НЕПРАВИЛЬНО — теряется центрирование
ScrollView {
    GeometryReader { geo in
        // контент вытягивается на всю ширину
    }
}

// ✅ ПРАВИЛЬНО — HStack для центрирования
ScrollView {
    HStack(spacing: 0) {
        Spacer(minLength: 0)
        
        GeometryReader { geo in
            // контент с вычислениями
            let blockTopY = geo.frame(in: .global).minY
            let availableHeight = screenHeight - safeAreaBottom - standardPadding - blockTopY
            
            VStack {
                // контент
            }
            .frame(height: availableHeight)
        }
        .frame(width: contentWidth) // Ограничиваем ширину
        
        Spacer(minLength: 0)
    }
}
```

**Важно:**
- `Spacer(minLength: 0)` необходим для корректного распределения пространства
- `.frame(width: contentWidth)` ограничивает ширину GeometryReader
- Центрирование работает автоматически благодаря Spacer'ам


================================================================================
5. PATTERN: Динамическая высота на основе safe area
================================================================================

**Формула расчета:**
```
availableBlockHeight = screenHeight - safeAreaBottom - standardPadding - blockTopY
```

**Полная реализация:**

```swift
private func tacticalSection(
    contentWidth: CGFloat,
    maxHeight: CGFloat,
    screenHeight: CGFloat,
    safeAreaTop: CGFloat,
    safeAreaBottom: CGFloat,
    safeAreaBottomPadding: CGFloat
) -> some View {
    let options = store.run?.roomOptions ?? []
    let standardSpacing: CGFloat = 12
    
    return HStack(spacing: 0) {
        Spacer(minLength: 0)
        
        GeometryReader { geo in
            // Вычисляем доступную высоту блока
            let blockTopY = geo.frame(in: .global).minY
            let standardPadding: CGFloat = 12
            let availableBlockHeight = max(0, screenHeight - safeAreaBottom - standardPadding - blockTopY)
            
            // Вычисляем высоту карточек
            let cardCount = CGFloat(options.count)
            let totalSpacing = standardSpacing * max(0, cardCount - 1)
            let availableHeightForCards = max(0, availableBlockHeight - totalSpacing)
            let cardHeight = cardCount > 0 ? max(0, availableHeightForCards / cardCount) : 0
            
            VStack(spacing: standardSpacing) {
                ForEach(options) { option in
                    TacticalRoomCardView(room: option) {
                        store.selectRoom(option)
                    }
                    .frame(width: contentWidth)
                    .frame(height: cardHeight) // Фиксированная высота
                }
            }
            .frame(width: contentWidth)
            .frame(height: availableBlockHeight) // Жёстко ограничиваем высоту блока
        }
        .frame(width: contentWidth)
        
        Spacer(minLength: 0)
    }
}
```

**Компоненты формулы:**
- `screenHeight` - высота экрана (из GeometryReader на уровне экрана)
- `safeAreaBottom` - нижний отступ safe area
- `standardPadding` - стандартный отступ от нижней границы safe area (12px)
- `blockTopY` - Y-координата верха блока (из `.global` координат)


================================================================================
6. PATTERN: Равномерное распределение карточек
================================================================================

**Формула:**
```
totalSpacing = standardSpacing * (cardCount - 1)
availableHeightForCards = availableBlockHeight - totalSpacing
cardHeight = availableHeightForCards / cardCount
```

**Пример:**

```swift
let cardCount: CGFloat = 3
let standardSpacing: CGFloat = 12

// Общее пространство для отступов между карточками
let totalSpacing = standardSpacing * (cardCount - 1) // 12 * 2 = 24

// Доступная высота для карточек (исключаем отступы)
let availableHeightForCards = availableBlockHeight - totalSpacing

// Высота каждой карточки
let cardHeight = availableHeightForCards / cardCount
```

**Результат:**
- 3 карточки равномерно распределяются по доступной высоте
- Между карточками сохраняется отступ 12px
- Карточки заполняют всё доступное пространство


================================================================================
7. ЧЕКЛИСТ ДЛЯ РЕАЛИЗАЦИИ ПОХОЖИХ LAYOUT'ОВ
================================================================================

При реализации экрана с динамической высотой на основе safe area:

- [ ] Определить, какие секции нуждаются в динамической высоте
- [ ] Создать PreferenceKey для передачи позиции (если нужна передача в родителя)
- [ ] Использовать `.global` координаты для измерения позиции
- [ ] Реализовать формулу расчета высоты: `screenHeight - safeAreaBottom - padding - topY`
- [ ] Обернуть GeometryReader в HStack со Spacer'ами для центрирования
- [ ] Ограничить ширину GeometryReader через `.frame(width: contentWidth)`
- [ ] Использовать стандартные отступы (12px) для консистентности
- [ ] Реализовать равномерное распределение карточек (если применимо)
- [ ] Протестировать на разных размерах экранов
- [ ] Проверить, что контент не выходит за пределы safe area


================================================================================
8. ИЗВЛЕЧЕННЫЕ ПРАВИЛА
================================================================================

**Правило 1:** GeometryReader в ScrollView требует HStack для центрирования
- `GeometryReader` расширяется на всю ширину по умолчанию
- Для центрирования обернуть в `HStack` со `Spacer'ами`

**Правило 2:** Динамическая высота на основе safe area требует `.global` координат
- Используй `geo.frame(in: .global).minY` для измерения позиции
- Высота: `screenHeight - safeAreaBottom - standardPadding - blockTopY`

**Правило 3:** PreferenceKey для передачи layout информации
- Используй для передачи позиции/размера между вьюхами
- Помогает вычислять динамические размеры на основе реальных позиций

**Правило 4:** Стандартные отступы между секциями
- Используй единый стандарт: 12px между основными секциями
- Обеспечивает консистентность и упрощает поддержку

**Правило 5:** Динамический расчет высоты карточек
- Высота карточек = `(availableBlockHeight - totalSpacing) / cardCount`
- Обеспечивает равномерное распределение пространства


================================================================================
9. ССЫЛКИ НА РОДСТВЕННЫЕ ДОКУМЕНТЫ
================================================================================

- `UI_DESIGN_RULES.md` - общие правила UI layout'а (раздел "Динамические layout'ы")
- `ui_kit_system_fb314574.plan.md` - план реализации UI Kit System
- `TowerView.swift` - полная реализация паттернов


================================================================================
Последнее обновление: Январь 2026 (после реализации TowerView)
================================================================================
