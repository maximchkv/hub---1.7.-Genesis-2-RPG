import SwiftUI

// VS1.0 — Global Design System: UIStyle
// Один источник правды для фона, цветов, радиусов, отступов и базовых стилей.

enum UIStyle {

    // MARK: - Background
    // Использование:
    // UIStyle.background().ignoresSafeArea()
    static func background() -> some View {
        Image("bg_parchment")
            .resizable()
            .scaledToFill()
    }

    // MARK: - Palette
    // Важно: НЕ называем это "Color", чтобы не конфликтовать с SwiftUI.Color
    enum Colors {
        static let parchment   = SwiftUI.Color(red: 0.96, green: 0.94, blue: 0.90)
        static let inkPrimary  = SwiftUI.Color(red: 0.20, green: 0.18, blue: 0.15)
        static let inkSecondary = SwiftUI.Color(red: 0.45, green: 0.42, blue: 0.38)

        static let cardFill    = SwiftUI.Color.white.opacity(0.65)
        static let cardStroke  = SwiftUI.Color.black.opacity(0.08)

        static let accent      = SwiftUI.Color(red: 0.55, green: 0.45, blue: 0.30)
        static let mutedFill   = SwiftUI.Color.black.opacity(0.06)

        // Consistent HP green (used across UI)
        static let hpGreen     = SwiftUI.Color(red: 0.12, green: 0.45, blue: 0.20)
    }

    // MARK: - Radius
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 14

    // MARK: - Spacing (базовые отступы)
    enum Spacing {
        static let xs: CGFloat = 4      // Для плотных интерфейсов
        static let s: CGFloat = 8       // Мелкие отступы
        static let m: CGFloat = 12      // Средние отступы (стандарт между секциями)
        static let l: CGFloat = 16      // Большие отступы
        static let xl: CGFloat = 24     // Очень большие отступы
        static let xxl: CGFloat = 32   // Максимальные отступы
        
        // Семантические отступы
        static let section: CGFloat = 16  // Между секциями
        static let block: CGFloat = 12    // Между блоками внутри секции
        static let element: CGFloat = 8   // Между элементами
    }

    // MARK: - Card wrapper
    // Использование:
    // VStack { ... }.uiCard()
    struct CardModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: UIStyle.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                        .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
                )
        }
    }

    // MARK: - Primary button style
    // Использование:
    // Button("...") { ... }.buttonStyle(UIStyle.PrimaryButtonStyle())
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: UIStyle.buttonRadius)
                        .fill(UIStyle.Colors.accent)
                        .opacity(configuration.isPressed ? 0.85 : 1.0)
                )
        }
    }

    // MARK: - Card button style
    // Использование:
    // Button { ... } label: { ... }.buttonStyle(UIStyle.CardButtonStyle())
    //
    // Предполагается, что label уже оформлен как карточка (например через `.uiCard()`).
    struct CardButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
                .opacity(configuration.isPressed ? 0.96 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                        .stroke(UIStyle.Colors.accent.opacity(configuration.isPressed ? 0.28 : 0.0), lineWidth: 1)
                )
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    // MARK: - Layout System
    
    enum Layout {
        // MARK: - ContentWidthProvider
        // Утилита для расчета ширины контента с капами
        // Использование:
        // GeometryReader { geo in
        //     let contentWidth = Layout.contentWidth(
        //         geometry: geo,
        //         horizontalPadding: 24,
        //         sizeClass: hSizeClass
        //     )
        // }
        static func contentWidth(
            geometry: GeometryProxy,
            horizontalPadding: CGFloat = 24,
            sizeClass: UserInterfaceSizeClass? = nil
        ) -> CGFloat {
            let availableWidth = max(0, geometry.size.width - horizontalPadding * 2)
            let cap = widthCap(for: sizeClass, windowWidth: geometry.size.width)
            return min(availableWidth, cap)
        }
        
        // Вспомогательная функция для расчета капа ширины
        private static func widthCap(for sizeClass: UserInterfaceSizeClass?, windowWidth: CGFloat) -> CGFloat {
            switch sizeClass {
            case .compact:
                return 360 // iPhone
            case .regular:
                return windowWidth < 900 ? 600 : 720 // iPad / широкие окна
            default:
                return 360
            }
        }
        
        // MARK: - ScreenContainer
        // Базовый контейнер экрана с правильной обработкой фона
        // Использование:
        // Layout.ScreenContainer {
        //     ScrollView {
        //         // контент
        //     }
        // }
        struct ScreenContainer<Content: View>: View {
            let content: () -> Content
            
            init(@ViewBuilder content: @escaping () -> Content) {
                self.content = content
            }
            
            var body: some View {
                content()
                    .background {
                        UIStyle.background()
                            .ignoresSafeArea()
                    }
            }
        }
        
        // MARK: - FixedHeaderScreen
        // Паттерн для экрана с фиксированным заголовком поверх ScrollView
        // Использование:
        // Layout.FixedHeaderScreen(
        //     header: { contentWidth in HeaderView() },
        //     headerHeight: 92,
        //     headerTopPadding: 10,
        //     headerBottomGap: 14
        // ) { contentWidth in
        //     ScrollView {
        //         // контент использует contentWidth
        //     }
        // }
        struct FixedHeaderScreen<Header: View, Content: View>: View {
            @Environment(\.horizontalSizeClass) private var hSizeClass
            
            let header: (CGFloat) -> Header
            let headerHeight: CGFloat
            let headerTopPadding: CGFloat
            let headerBottomGap: CGFloat
            let horizontalPadding: CGFloat
            let content: (CGFloat) -> Content
            
            init(
                headerHeight: CGFloat,
                headerTopPadding: CGFloat = 10,
                headerBottomGap: CGFloat = 14,
                horizontalPadding: CGFloat = 24,
                @ViewBuilder header: @escaping (CGFloat) -> Header,
                @ViewBuilder content: @escaping (CGFloat) -> Content
            ) {
                self.header = header
                self.headerHeight = headerHeight
                self.headerTopPadding = headerTopPadding
                self.headerBottomGap = headerBottomGap
                self.horizontalPadding = horizontalPadding
                self.content = content
            }
            
            var body: some View {
                GeometryReader { geo in
                    let contentWidth = Layout.contentWidth(
                        geometry: geo,
                        horizontalPadding: horizontalPadding,
                        sizeClass: hSizeClass
                    )
                    
                    ZStack(alignment: .top) {
                        // CONTENT (scrollable) — ниже fixed header
                        content(contentWidth)
                            .padding(.top, headerHeight + headerTopPadding + headerBottomGap)
                        
                        // HEADER (fixed)
                        header(contentWidth)
                            .frame(width: contentWidth)
                            .frame(height: headerHeight)
                            .padding(.top, headerTopPadding)
                            .frame(maxWidth: .infinity, alignment: .top)
                            .padding(.horizontal, horizontalPadding)
                    }
                }
                .background {
                    UIStyle.background()
                        .ignoresSafeArea()
                }
            }
        }
        
        // MARK: - StandardHeader
        // Стандартный заголовок с кнопкой назад и опциональными действиями
        // Использование:
        // Layout.StandardHeader(
        //     title: "Башня",
        //     onBack: { store.goToHub() }
        // )
        struct StandardHeader: View {
            let title: String
            let onBack: (() -> Void)?
            let trailingContent: AnyView?
            
            // Инициализатор без trailing content
            init(
                title: String,
                onBack: (() -> Void)? = nil
            ) {
                self.title = title
                self.onBack = onBack
                self.trailingContent = nil
            }
            
            // Инициализатор с trailing content
            init<TrailingContent: View>(
                title: String,
                onBack: (() -> Void)? = nil,
                @ViewBuilder trailingContent: () -> TrailingContent
            ) {
                self.title = title
                self.onBack = onBack
                self.trailingContent = AnyView(trailingContent())
            }
            
            var body: some View {
                HStack {
                    if let onBack = onBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(UIStyle.Colors.inkPrimary)
                        }
                    } else {
                        Spacer()
                            .frame(width: 24) // Для центрирования заголовка
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(UIStyle.Colors.inkPrimary)
                    
                    Spacer()
                    
                    if let trailingContent = trailingContent {
                        trailingContent
                    } else {
                        Spacer()
                            .frame(width: 24) // Для центрирования заголовка
                    }
                }
                .padding(.horizontal, UIStyle.Spacing.xl)
                .padding(.vertical, UIStyle.Spacing.s)
            }
        }
    }
}

// MARK: - View helpers
extension View {
    func uiCard() -> some View {
        self.modifier(UIStyle.CardModifier())
    }
    
    // ⚠️ УДАЛЕНЫ хелперы uiSafeAreaScreenPadding и uiMaxReadableWidth.
    // Они не работали надёжно и привели к 7 итерациям багфикса RewardView.
    // Используй простой .padding() на контенте — см. UI_DESIGN_RULES.md
}
