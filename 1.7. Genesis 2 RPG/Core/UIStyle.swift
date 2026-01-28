import SwiftUI

// VS1.0 — Global Design System: UIStyle
// Один источник правды для фона, цветов, радиусов, отступов и базовых стилей.

enum UIStyle {

    // MARK: - Background
    // Использование:
    // UIStyle.background().ignoresSafeArea()
    static func background() -> some View {
        ZStack {
            // Ink gradient base
            LinearGradient(
                colors: [
                    Colors.bgInkDeep,
                    Colors.bgInkSoft,
                    Colors.bgInkCenter
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Prismatic reflections — large, blurred, only near edges
            RadialGradient(
                colors: [
                    Colors.reflectionCyan,
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 420
            )
            .blur(radius: 60)
            .opacity(0.9)
            
            RadialGradient(
                colors: [
                    Colors.reflectionMagenta,
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 420
            )
            .blur(radius: 70)
            .opacity(0.9)
            
            // Subtle parchment texture as liquid noise overlay
            Image("bg_parchment")
                .resizable()
                .scaledToFill()
                .opacity(0.22)
                .blur(radius: 1)
                .blendMode(.softLight)
        }
    }

    // MARK: - Palette
    // Важно: НЕ называем это "Color", чтобы не конфликтовать с SwiftUI.Color
    enum Colors {
        // Base Ink Backgrounds
        static let bgInkDeep   = SwiftUI.Color(red: 0.02, green: 0.02, blue: 0.04)  // #05060A
        static let bgInkSoft   = SwiftUI.Color(red: 0.04, green: 0.06, blue: 0.09)  // #0A0E18
        static let bgInkCenter = SwiftUI.Color(red: 0.06, green: 0.09, blue: 0.15)  // #101826

        // Glass / Liquid Surfaces
        static let liquidGlassLow   = SwiftUI.Color.white.opacity(0.05)
        static let liquidGlassMid   = SwiftUI.Color.white.opacity(0.10)
        static let liquidGlassHigh  = SwiftUI.Color.white.opacity(0.16)
        static let liquidStroke     = SwiftUI.Color.white.opacity(0.18)

        // Text
        static let textPrimary   = SwiftUI.Color(red: 0.93, green: 0.94, blue: 0.96) // #EDEFF5
        static let textSecondary = SwiftUI.Color(red: 0.73, green: 0.75, blue: 0.81) // #B9C0CF
        static let textMuted     = SwiftUI.Color(red: 0.49, green: 0.53, blue: 0.61) // #7E879B

        // Accent (Chrome-like)
        static let chromeGold           = SwiftUI.Color(red: 0.72, green: 0.61, blue: 0.39) // #B79B63
        static let chromeGoldHighlight  = SwiftUI.Color(red: 0.89, green: 0.81, blue: 0.64) // #E3CFA3

        // Iridescent lights (never as solid fills, only glows/reflections)
        static let iridescentCyan     = SwiftUI.Color(red: 0.50, green: 0.91, blue: 1.00)   // #7FE9FF
        static let iridescentMagenta  = SwiftUI.Color(red: 1.00, green: 0.47, blue: 0.85)   // #FF78DA

        // Derived light tokens
        static let edgeCyanGlow    = iridescentCyan.opacity(0.12)
        static let edgeMagentaGlow = iridescentMagenta.opacity(0.10)

        static let specularLineSoft = SwiftUI.Color.white.opacity(0.18)
        static let specularLineIridescent = SwiftUI.Color(
            red: 0.50, green: 0.91, blue: 1.00
        )

        static let reflectionCyan    = iridescentCyan.opacity(0.08)
        static let reflectionMagenta = iridescentMagenta.opacity(0.08)

        // Legacy aliases (for compatibility with existing code)
        static let parchment   = bgInkCenter
        static let inkPrimary  = textPrimary
        static let inkSecondary = textSecondary

        static let cardFill    = liquidGlassMid
        static let cardStroke  = liquidStroke

        static let accent      = chromeGold
        static let mutedFill   = SwiftUI.Color.white.opacity(0.04)

        // Consistent HP green (used across UI) — kept as-is
        static let hpGreen     = SwiftUI.Color(red: 0.12, green: 0.45, blue: 0.20)
        
        // Dark green for highlighting growing numbers (used in reward cards)
        static let growthGreen = SwiftUI.Color(red: 0.10, green: 0.50, blue: 0.15)
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
        static let xxl: CGFloat = 32    // Максимальные отступы
        
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
                .background(
                    RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                        .fill(
                            UIStyle.Colors.liquidGlassMid
                                .opacity(0.95)
                        )
                        .background(
                            UIStyle.Colors.bgInkCenter.opacity(0.4)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                        .strokeBorder(
                            UIStyle.Colors.cardStroke,
                            lineWidth: 1
                        )
                        .shadow(
                            color: UIStyle.Colors.edgeCyanGlow.opacity(0.45),
                            radius: 12,
                            x: -2,
                            y: -2
                        )
                        .shadow(
                            color: UIStyle.Colors.edgeMagentaGlow.opacity(0.45),
                            radius: 18,
                            x: 3,
                            y: 6
                        )
                )
                .shadow(
                    color: SwiftUI.Color.black.opacity(0.60),
                    radius: 30,
                    x: 0,
                    y: 26
                )
        }
    }

    // MARK: - Primary button style
    // Использование:
    // Button("...") { ... }.buttonStyle(UIStyle.PrimaryButtonStyle())
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            let isPressed = configuration.isPressed
            
            return configuration.label
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(UIStyle.Colors.bgInkDeep.opacity(0.96))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .padding(.horizontal, 2)
                .background(
                    ZStack {
                        // Base liquid gold gradient
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        UIStyle.Colors.chromeGold,
                                        UIStyle.Colors.chromeGoldHighlight
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                        
                        // Inner depth
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius, style: .continuous)
                            .fill(
                                SwiftUI.Color.black.opacity(isPressed ? 0.22 : 0.14)
                            )
                            .blendMode(.softLight)
                        
                        // Specular line highlight
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        UIStyle.Colors.specularLineSoft.opacity(0.0),
                                        UIStyle.Colors.specularLineSoft.opacity(isPressed ? 0.9 : 1.0),
                                        UIStyle.Colors.specularLineSoft.opacity(0.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.2
                            )
                            .offset(y: isPressed ? 2 : -4)
                            .blur(radius: isPressed ? 1.5 : 0.8)
                            .opacity(0.9)
                        
                        // Iridescent edge glow (very subtle)
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius + 2, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        UIStyle.Colors.edgeCyanGlow,
                                        UIStyle.Colors.edgeMagentaGlow
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .blur(radius: 3)
                            .opacity(isPressed ? 0.7 : 0.9)
                    }
                    .compositingGroup()
                    .shadow(
                        color: SwiftUI.Color.black.opacity(0.65),
                        radius: isPressed ? 14 : 22,
                        x: 0,
                        y: isPressed ? 8 : 14
                    )
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.18), value: isPressed)
        }
    }

    // MARK: - Card button style
    // Использование:
    // Button { ... } label: { ... }.buttonStyle(UIStyle.CardButtonStyle())
    //
    // Предполагается, что label уже оформлен как карточка (например через `.uiCard()`).
    struct CardButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            let isPressed = configuration.isPressed
            
            return configuration.label
                .scaleEffect(isPressed ? 0.985 : 1.0)
                .opacity(isPressed ? 0.96 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: UIStyle.cardRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    UIStyle.Colors.edgeCyanGlow.opacity(isPressed ? 0.5 : 0.3),
                                    UIStyle.Colors.edgeMagentaGlow.opacity(isPressed ? 0.5 : 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPressed ? 1.4 : 1
                        )
                        .blur(radius: isPressed ? 1.2 : 0.6)
                )
                .animation(.easeInOut(duration: 0.16), value: isPressed)
        }
    }
    
    // MARK: - Secondary button style (Liquid Glass)
    // Использование:
    // Button("...") { ... }.buttonStyle(UIStyle.SecondaryButtonStyle())
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            let isPressed = configuration.isPressed
            
            return configuration.label
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(UIStyle.Colors.textPrimary.opacity(isPressed ? 0.9 : 1.0))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    ZStack {
                        // Liquid glass body
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        UIStyle.Colors.liquidGlassLow,
                                        UIStyle.Colors.liquidGlassMid
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .background(
                                UIStyle.Colors.bgInkCenter.opacity(0.6)
                            )
                        
                        // Inner blur impression (simulated with soft light)
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius, style: .continuous)
                            .fill(
                                SwiftUI.Color.white.opacity(isPressed ? 0.06 : 0.10)
                            )
                            .blendMode(.softLight)
                        
                        // Iridescent stroke
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        UIStyle.Colors.edgeCyanGlow.opacity(isPressed ? 0.7 : 0.5),
                                        UIStyle.Colors.edgeMagentaGlow.opacity(isPressed ? 0.6 : 0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .blur(radius: isPressed ? 1.3 : 0.8)
                    }
                    .shadow(
                        color: SwiftUI.Color.black.opacity(0.55),
                        radius: isPressed ? 10 : 16,
                        x: 0,
                        y: isPressed ? 6 : 10
                    )
                )
                .opacity(isPressed ? 0.96 : 1.0)
                .scaleEffect(isPressed ? 0.985 : 1.0)
                .animation(.easeInOut(duration: 0.16), value: isPressed)
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
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(UIStyle.Colors.textSecondary)
                        }
                    } else {
                        Spacer()
                            .frame(width: 24) // Для центрирования заголовка
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .kerning(-0.6)
                        .foregroundStyle(UIStyle.Colors.textPrimary)
                    
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

    // MARK: - Segmented Control (Liquid Rail)
    struct LiquidSegmentedControl<Option: Hashable>: View {
        let options: [Option]
        let titleProvider: (Option) -> String
        @Binding var selection: Option
        
        private let railHeight: CGFloat = 40
        
        var body: some View {
            ZStack {
                // Glass rail background
                RoundedRectangle(cornerRadius: railHeight / 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Colors.liquidGlassLow,
                                Colors.liquidGlassMid.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .background(Colors.bgInkCenter.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: railHeight / 2, style: .continuous)
                            .strokeBorder(
                                Colors.liquidStroke.opacity(0.8),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: SwiftUI.Color.black.opacity(0.6),
                        radius: 18,
                        x: 0,
                        y: 12
                    )
                
                GeometryReader { geo in
                    let count = max(1, options.count)
                    let segmentWidth = geo.size.width / CGFloat(count)
                    
                    ZStack(alignment: .leading) {
                        // Active chrome capsule
                        RoundedRectangle(cornerRadius: railHeight / 2, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Colors.chromeGold,
                                        Colors.chromeGoldHighlight
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: railHeight / 2, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Colors.edgeCyanGlow,
                                                Colors.edgeMagentaGlow
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: railHeight / 2, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Colors.specularLineSoft.opacity(0.0),
                                                Colors.specularLineSoft.opacity(1.0),
                                                Colors.specularLineSoft.opacity(0.0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1.2
                                    )
                                    .offset(y: -3)
                                    .blur(radius: 0.8)
                            )
                            .frame(width: segmentWidth - 6, height: railHeight - 6)
                            .padding(.vertical, 3)
                            .offset(x: xOffsetForSelection(width: segmentWidth))
                            .animation(.easeInOut(duration: 0.22), value: selection)
                        
                        HStack(spacing: 0) {
                            ForEach(options, id: \.self) { option in
                                let isActive = option == selection
                                
                                Button {
                                    if selection != option {
                                        withAnimation(.easeInOut(duration: 0.22)) {
                                            selection = option
                                        }
                                    }
                                } label: {
                                    Text(titleProvider(option))
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .kerning(-0.4)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .foregroundStyle(
                                            isActive
                                            ? Colors.bgInkDeep.opacity(0.96)
                                            : Colors.textSecondary.opacity(0.9)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .frame(height: railHeight)
        }
        
        private func xOffsetForSelection(width: CGFloat) -> CGFloat {
            guard let index = options.firstIndex(of: selection) else { return 0 }
            let base = CGFloat(index) * width
            return base + 3
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
