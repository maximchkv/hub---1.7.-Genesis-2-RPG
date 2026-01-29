================================================================================
                 UI RULES (SwiftUI) — GENESIS 2 RPG (Liquid Ink)
================================================================================

Цель: чтобы **ни один экран** не "уезжал" под вырез/края и выглядел консистентно
и при этом ощущался как интерфейс из жидкого стекла и хрома,
освещённый мягким неоном (Liquid Ink × Prismatic Chrome × Ethereal Anime).


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
МАТЕРИАЛЫ И ЦВЕТА (LIQUID INK / CHROME)
================================================================================

Все визуальные решения опираются на `UIStyle.Colors`:

- База (Ink Background):
  - `bgInkDeep`, `bgInkSoft`, `bgInkCenter` — тёмный ink-градиент сцены.
- Стекло (Liquid Glass):
  - `liquidGlassLow`, `liquidGlassMid`, `liquidGlassHigh`, `liquidStroke`.
- Текст:
  - `textPrimary`, `textSecondary`, `textMuted` — спокойная, приглушённая типографика.
- Акцент (Chrome Gold):
  - `chromeGold`, `chromeGoldHighlight` — хромированное золото для primary-акцентов.
- Иридесценция (только свет, не solid!):
  - `iridescentCyan`, `iridescentMagenta` — используются **только** как glows/рефлексы.
  - `edgeCyanGlow`, `edgeMagentaGlow`, `specularLineSoft`, `reflectionCyan`, `reflectionMagenta`.
- Семантика боя / башни:
  - `hpGreen`, `healProtection` — **тёмный** зелёный для здоровья и полосы HP (читаемость на светлом материале).
  - `threatRed`, `threatOrange`, `damageThreat` — урон и угроза.

Запрет:
- Не использовать `iridescentCyan`/`iridescentMagenta` как сплошную заливку.
- Только:
  - мягкие edge-glow,
  - размазанные пятна фона,
  - тонкие specular-линии.


================================================================================
ПРОСТЫЕ ПРАВИЛА LAYOUT + ФОН
================================================================================

### Фон
- Всегда через `.background { UIStyle.background().ignoresSafeArea() }`
- НЕ через ZStack с фоном первым элементом (кроме задокументированных исключений)
- `UIStyle.background()` уже содержит:
  - ink-градиент,
  - крупные размазанные призматические блики по краям (особенно снизу),
  - спокойный центр под контент.

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
        UIStyle.Layout.ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: UIStyle.Spacing.l) {
                    Text("Заголовок")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .kerning(-0.6)
                        .foregroundStyle(UIStyle.Colors.textPrimary)
                    
                    // остальной контент...
                }
                .padding(.horizontal, UIStyle.Spacing.xl)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
```


================================================================================
ТИПОГРАФИКА (МИНИМАЛЬНАЯ МИМИКА)
================================================================================

- Базовый стиль:
  - `SF Pro Rounded` / Display.
- Заголовки:
  - Semibold, дизайн `.rounded`, `kerning(-0.6)`.
  - Без экстремальных размеров и жирности.
- Body:
  - Regular / Medium, увеличенный `lineSpacing`, цвета `textSecondary` по умолчанию.
- Кнопки:
  - Semibold, Sentence case (без UPPERCASE), дизайн `.rounded`.

Принцип:
- Читаемость и иерархия за счёт веса, kerning и слоя (фон/материал), а не за счёт резкого контраста.


================================================================================
КАРТОЧКИ / ПАНЕЛИ — SYNTHETIC SKIN
================================================================================

Все карточные/панельные поверхности должны ходить через `View.uiCard()` — это единая реализация
\"synthetic skin\" (liquid glass + мягкие тени + иридесцентный край).

```swift
VStack {
    // контент карточки
}
.uiCard()
```

`uiCard()`:
- фон: `liquidGlassMid` поверх `bgInkCenter`,
- бордер: `liquidStroke` + мягкий edge-glow,
- тень: широкая, мягкая, без резких линий.

Текст внутри карточек (инфоблоки и др.):
- В блоках с `.uiCard()` **не использовать белый или почти белый шрифт** — на стекле он плохо читается.
- Использовать для текста: `textSecondary` (основной текст, заголовки инфоблоков), `textMuted` (второстепенный текст).
- Не использовать: `Color.white`, `.white`, `textPrimary` / `inkPrimary` внутри инфоблоков.

Запрет:
- не рисовать свои `.background(.thinMaterial)` и `.stroke` вокруг карточек,
  если можно использовать `.uiCard()`.


================================================================================
КНОПКИ — LIQUID GOLD / LIQUID GLASS
================================================================================

Primary (Liquid Gold):
- `Button { ... }.buttonStyle(UIStyle.PrimaryButtonStyle())`
- Pill-форма (RoundedRectangle с большим радиусом),
- фон: градиент `chromeGold → chromeGoldHighlight`,
- тонкая specular-линия сверху,
- press:
  - `scaleEffect(0.98)`,
  - лёгкое затемнение и смещение хайлайта,
  - тень чуть короче.

Secondary (Liquid Glass):
- `Button { ... }.buttonStyle(UIStyle.SecondaryButtonStyle())`
- фон: `liquidGlassLow → liquidGlassMid` с мягким inner light,
- stroke: иридесцентный, но слабый (`edgeCyanGlow`, `edgeMagentaGlow`),
- press:
  - небольшое уменьшение opacity и scale,
  - без резких скачков цвета.


================================================================================
СЕГМЕНТЫ / ТАБЫ — LIQUID RAIL
================================================================================

Для сегментов Climb / Cards / Castle / Collect и похожих переключателей
используется `UIStyle.LiquidSegmentedControl`.

```swift
UIStyle.LiquidSegmentedControl(
    options: [CastleUIMode.build, CastleUIMode.upgrade],
    titleProvider: { $0.rawValue },
    selection: $store.castleModeUI
)
```

Rail:
- стеклянный контейнер (liquid glass + liquidStroke),
- мягкая широкая тень.

Активный сегмент:
- капля жидкого хрома (chromeGold + chromeGoldHighlight),
- мягкий edge glow и specular-линия,
- анимация переключения — `easeInOut(0.22)`, двигается в основном **свет**, а не геометрия.

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
ПРИМЕРЫ МИГРАЦИИ (LAYOUT)
================================================================================

### Простой экран (EventView, ChestView, RestView, DefeatView, VictoryView)

**До:**
```swift
var body: some View {
    VStack(spacing: 16) {
        Text("Заголовок")
        // контент
    }
    .padding()
}
```

**После:**
```swift
var body: some View {
    UIStyle.Layout.ScreenContainer {
        ScrollView {
            VStack(alignment: .leading, spacing: UIStyle.Spacing.l) {
                Text("Заголовок")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                // контент
            }
            .padding(.horizontal, UIStyle.Spacing.xl)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
    }
}
```

### Экран с фиксированным заголовком (HubView)

**До:**
```swift
ZStack {
    UIStyle.background().ignoresSafeArea()
    GeometryReader { geo in
        ZStack(alignment: .top) {
            ScrollView { /* контент */ }
            headerCard // fixed
        }
    }
}
```

**После:**
```swift
UIStyle.Layout.FixedHeaderScreen(
    headerHeight: 92,
    headerTopPadding: 10,
    headerBottomGap: 14,
    header: { contentWidth in
        headerCard
    }
) { contentWidth in
    ScrollView {
        // контент
    }
}
```

### Экран с динамической высотой (TowerView)

**Особый случай:** TowerView использует динамическую высоту тактической секции на основе safe area через PreferenceKey. Это задокументировано в `TOWERVIEW_LAYOUT_PATTERNS.md`.

**Миграция:**
- Фон заменен на `ScreenContainer`
- Используется `ContentWidthProvider`
- Отступы стандартизированы
- Динамическая высота сохранена (специфическая функциональность)

### Полноэкранный экран (BattleView)

**Особый случай:** BattleView использует полноэкранный layout с bottom controls, pinned to bottom edge (не используют safe area bottom).

**Миграция:**
- Фон заменен на `ScreenContainer`
- Используется `ContentWidthProvider`
- Отступы стандартизированы
- Полноэкранный layout сохранен (специфическая функциональность)

### Экран с interactive background (StartView)

**Исключение:** StartView использует interactive background (LanternRevealLayer) с `.ignoresSafeArea()`, что требует ZStack. Оставлен как есть - это специфическая функциональность экрана входа.

**Примечание:** StartView не мигрирован на ScreenContainer, так как interactive background требует особого подхода. Это допустимое исключение для экрана входа.

================================================================================
ЧЕКЛИСТ МИГРАЦИИ
================================================================================

Для каждого экрана при миграции проверять:

- [ ] Заменен ZStack на `.background { }` паттерн (через ScreenContainer) или документировано исключение
- [ ] Используется `ContentWidthProvider` для расчета ширины (или документировано исключение)
- [ ] Используется `StandardHeader` для заголовков (или документировано исключение)
- [ ] Отступы стандартизированы через `UIStyle.Spacing`
- [ ] Safe area обрабатывается корректно
- [ ] Проверено на iPhone с Dynamic Island
- [ ] Проверено в landscape (если поддерживается)
- [ ] Контент не выходит за пределы safe area
- [ ] Отступы от краев минимум 20-24pt

================================================================================
ИСКЛЮЧЕНИЯ ИЗ ПРАВИЛ
================================================================================

### StartView
- **Причина:** Interactive background (LanternRevealLayer) требует `.ignoresSafeArea()` и ZStack
- **Решение:** Оставлен как есть, документировано как исключение

### TowerView (частично)
- **Причина:** Динамическая высота тактической секции на основе safe area через PreferenceKey
- **Решение:** Фон мигрирован на ScreenContainer, динамическая высота сохранена
- **Документация:** `TOWERVIEW_LAYOUT_PATTERNS.md`

### BattleView (частично)
- **Причина:** Полноэкранный layout с bottom controls pinned to bottom edge
- **Решение:** Фон мигрирован на ScreenContainer, полноэкранный layout сохранен

================================================================================
Последнее обновление: Январь 2026 (после миграции UI Kit по всем экранам)
================================================================================
