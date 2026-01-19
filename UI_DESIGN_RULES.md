================================================================================
                         UI RULES (SwiftUI) — GENESIS 2 RPG
================================================================================

Цель: чтобы **ни один экран** не "уезжал" под вырез/края и выглядел консистентно.


================================================================================
ГЛАВНОЕ ПРАВИЛО (после 7 итераций багфикса RewardView)
================================================================================

**Единственный надёжный паттерн для экрана с полноэкранным фоном:**

```swift
// ✅ ПРАВИЛЬНО — ScrollView корневой, фон в .background { }
ScrollView {
    VStack(alignment: .leading, spacing: 16) {
        // контент
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
}
.background {
    UIStyle.background()
        .ignoresSafeArea()
}
```

```swift
// ❌ НЕПРАВИЛЬНО — ZStack с фоном ломает safe area для ScrollView
ZStack {
    UIStyle.background()
        .ignoresSafeArea()
    
    ScrollView {
        // контент вылезает за края!
    }
}
```

**Почему ZStack не работает:**
Когда `ignoresSafeArea()` применён к элементу внутри `ZStack`, это может
"заразить" соседние элементы и `ScrollView` теряет связь с safe area.
Использование `.background { }` изолирует фон от layout контента.


================================================================================
SAFE AREA — ЧЕКЛИСТ
================================================================================

Перед коммитом любого UI-экрана:
- [ ] Проверен на **iPhone с Dynamic Island** (portrait).
- [ ] Проверен в **landscape** (если поддерживается).
- [ ] Контент **не залезает** под вырез/островок/скругления.
- [ ] Есть отступы от краёв минимум 20-24pt.


================================================================================
ПРОСТЫЕ ПРАВИЛА
================================================================================

### Фон
- Всегда через `.background { UIStyle.background().ignoresSafeArea() }`
- НЕ через ZStack с фоном первым элементом

### Отступы
- Простой `.padding()` на контенте внутри ScrollView
- Не нужны хелперы, safeAreaPadding, contentMargins — они добавляют сложность
- **Стандартные отступы между секциями:** 12px (`interBlock`, `metaToStrategic`, `strategicToTactical`)
- Это обеспечивает консистентность и упрощает поддержку

### ScrollView
- ScrollView как **корневой элемент** экрана
- Padding на **VStack внутри**, не на ScrollView

### Navigation Bar
- Если экран "fullscreen" без системного nav bar: `.toolbar(.hidden, for: .navigationBar)`


================================================================================
ШАБЛОН ЭКРАНА (копируй и используй)
================================================================================

```swift
struct SomeScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Заголовок")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                
                // остальной контент...
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .background {
            UIStyle.background()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
```

================================================================================
ДИНАМИЧЕСКИЕ LAYOUT'Ы И GEOMETRYREADER
================================================================================

### GeometryReader в ScrollView

**Проблема:** `GeometryReader` расширяется на всю ширину по умолчанию и теряет центрирование внутри `ScrollView`.

```swift
// ❌ НЕПРАВИЛЬНО — теряется центрирование
ScrollView {
    GeometryReader { geo in
        // контент
    }
}
```

```swift
// ✅ ПРАВИЛЬНО — HStack для центрирования
HStack(spacing: 0) {
    Spacer(minLength: 0)
    
    GeometryReader { geo in
        // контент с вычислениями
    }
    .frame(width: contentWidth) // Ограничиваем ширину
    
    Spacer(minLength: 0)
}
```

**Когда использовать:**
- Когда нужно измерять реальную позицию элемента в глобальных координатах
- Когда нужен динамический расчет высоты на основе safe area
- Когда контент внутри должен реагировать на изменения размера экрана

### Динамическая высота на основе safe area

**Паттерн для блоков, которые должны доходить до нижней границы safe area:**

```swift
GeometryReader { geo in
    // Вычисляем доступную высоту блока: от текущей позиции до нижней границы safe area
    let blockTopY = geo.frame(in: .global).minY
    let standardPadding: CGFloat = 12 // Стандартный отступ от safe area
    let availableHeight = max(0, screenHeight - safeAreaBottom - standardPadding - blockTopY)
    
    // Используем availableHeight для расчета высоты контента
    VStack {
        // контент
    }
    .frame(height: availableHeight)
}
```

**Важно:**
- Используй `.global` координаты (`geo.frame(in: .global).minY`) для измерения позиции относительно экрана
- Высота вычисляется: `screenHeight - safeAreaBottom - standardPadding - blockTopY`
- `standardPadding` обеспечивает отступ от нижней границы safe area

### PreferenceKey для передачи layout информации

**Когда нужно:** Для передачи позиции/размера от дочерних вьюх к родительским для динамических расчетов.

```swift
// 1. Определяем PreferenceKey
private struct TopYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 2. В дочерней вьюхе отправляем значение
.background(
    GeometryReader { geo in
        Color.clear.preference(key: TopYKey.self, value: geo.frame(in: .global).minY)
    }
)

// 3. В родительской вьюхе получаем значение
@State private var topY: CGFloat = 0

.onPreferenceChange(TopYKey.self) { value in
    topY = value
}

// 4. Используем topY для расчетов
let availableHeight = screenHeight - safeAreaBottom - standardPadding - topY
```

**Пример использования:**
- Передача позиции тактической секции для расчета доступной высоты
- Передача размеров дочерних элементов для адаптивного layout'а
- Синхронизация размеров между несколькими вьюхами

### Динамический расчет высоты карточек

**Паттерн для равномерного распределения карточек в доступном пространстве:**

```swift
let cardCount = CGFloat(options.count)
let standardSpacing: CGFloat = 12 // Отступ между карточками
let totalSpacing = standardSpacing * max(0, cardCount - 1)
let availableHeightForCards = max(0, availableBlockHeight - totalSpacing)
let cardHeight = cardCount > 0 ? max(0, availableHeightForCards / cardCount) : 0

ForEach(options) { option in
    CardView(option)
        .frame(height: cardHeight) // Фиксированная высота для равномерности
}
```

**Формула:**
- `availableHeightForCards = availableBlockHeight - totalSpacing`
- `cardHeight = availableHeightForCards / cardCount`

**Преимущества:**
- Карточки равномерно заполняют доступное пространство
- Автоматическая адаптация при изменении размера экрана
- Сохранение отступов между карточками


================================================================================
Последнее обновление: Январь 2026 (после фикса RewardView и TowerView)
================================================================================
