import SwiftUI

struct StartView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private let subtitle = "A parchment roguelike of cards, climbs, and a living castle."

    private let bullets: [String] = [
        "Climb a tower of floors and encounters.",
        "Fight turn-based battles using cards.",
        "Build up your castle between runs.",
        "Unlock and collect new cards over time."
    ]

    var body: some View {
        ZStack {
            UIStyle.backgroundImage()
                .ignoresSafeArea()

            GeometryReader { geo in
                // Поля по 24pt слева/справа
                let horizontalPadding: CGFloat = 24
                let availableWidth = max(0, geo.size.width - horizontalPadding * 2)

                // Верхний предел ширины — зависит от класса устройства и текущей ширины окна
                let cap = widthCap(for: hSizeClass, windowWidth: geo.size.width)

                // Итоговая ширина контента
                let contentWidth = min(availableWidth, cap)

                ViewThatFits(in: .vertical) {
                    // 1) Без скролла — если всё влезает
                    nonScrollLayout(contentWidth: contentWidth, horizontalPadding: horizontalPadding)

                    // 2) Авто-переход в скролл — если не влезло по высоте
                    scrollLayout(contentWidth: contentWidth, horizontalPadding: horizontalPadding)
                }
            }
        }
    }

    // Вычисляем верхний предел ширины
    private func widthCap(for sizeClass: UserInterfaceSizeClass?, windowWidth: CGFloat) -> CGFloat {
        switch sizeClass {
        case .compact:
            // iPhone-профиль
            return 360
        case .regular:
            // iPad/широкие окна
            if windowWidth < 900 {
                return 600
            } else {
                return 720
            }
        default:
            // На всякий случай — поведение как на iPhone
            return 360
        }
    }

    // MARK: - Layout blocks

    private func contentBlock(contentWidth: CGFloat) -> some View {
        VStack(spacing: 16) {

            // Title + subtitle
            VStack(spacing: 8) {
                Text("Genesis RPG")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(UIStyle.Color.inkPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(UIStyle.Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }

            // Onboarding card
            VStack(alignment: .leading, spacing: 10) {
                ForEach(bullets, id: \.self) { line in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .foregroundStyle(UIStyle.Color.inkSecondary)

                        Text(line)
                            .foregroundStyle(UIStyle.Color.inkPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.body)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .fill(UIStyle.Color.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .stroke(UIStyle.Color.cardStroke, lineWidth: 1)
            )

            // CTA button
            Button {
                store.startRun()
            } label: {
                Text("Start Run")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: UIStyle.buttonRadius)
                            .fill(UIStyle.Color.accent)
                    )
            }
        }
        .frame(width: contentWidth)
    }

    private func nonScrollLayout(contentWidth: CGFloat, horizontalPadding: CGFloat) -> some View {
        contentBlock(contentWidth: contentWidth)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func scrollLayout(contentWidth: CGFloat, horizontalPadding: CGFloat) -> some View {
        ScrollView(.vertical) {
            // Ключ: даём контейнеру ширину экрана, чтобы Spacer не схлопывался
            HStack {
                Spacer(minLength: 0)
                contentBlock(contentWidth: contentWidth)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
    }
}
