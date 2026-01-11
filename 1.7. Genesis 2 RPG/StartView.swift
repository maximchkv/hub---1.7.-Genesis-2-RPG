import SwiftUI

struct StartView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private let subtitle = "A parchment roguelike of cards, climbs, and a living castle."

    @State private var selectedChip: Chip = .climb

    private enum Chip: String, CaseIterable, Identifiable {
        case climb
        case cards
        case castle
        case collect

        var id: String { rawValue }

        var title: String {
            switch self {
            case .climb: return "Climb"
            case .cards: return "Cards"
            case .castle: return "Castle"
            case .collect: return "Collect"
            }
        }

        var onboardingTitle: String {
            switch self {
            case .climb: return "A tower run, one floor at a time"
            case .cards: return "Play cards, shape your turn"
            case .castle: return "Between runs, grow your base"
            case .collect: return "Unlock new tools over time"
            }
        }

        var onboardingLines: [String] {
            switch self {
            case .climb:
                return [
                    "Choose routes and face encounters.",
                    "Survive to reach the next floor.",
                    "Find rewards and adapt your build."
                ]
            case .cards:
                return [
                    "Turn-based combat with a small hand.",
                    "Spend your turn wisely.",
                    "Build a deck that fits your style."
                ]
            case .castle:
                return [
                    "Upgrade your castle between runs.",
                    "Unlock helpers and new options.",
                    "Return stronger on the next climb."
                ]
            case .collect:
                return [
                    "Earn and discover new cards.",
                    "Collect relics and artifacts.",
                    "Keep progression across runs."
                ]
            }
        }
    }

    var body: some View {
        ZStack {
            UIStyle.background()
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
                Text("Tower of Ink")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(UIStyle.Colors.inkPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(UIStyle.Colors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }

            // Chips row
            chipRow()

            // Onboarding card (swaps based on chip)
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    onboardingContent(for: selectedChip)
                        .id(selectedChip)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            )
                        )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .fill(UIStyle.Colors.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .stroke(UIStyle.Colors.cardStroke, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.22), value: selectedChip)

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
                            .fill(UIStyle.Colors.accent)
                    )
            }
        }
        .frame(width: contentWidth)
    }

    // MARK: - Chips + onboarding

    @ViewBuilder
    private func chipRow() -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                ForEach(Chip.allCases) { chip in
                    chipView(chip)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Chip.allCases) { chip in
                        chipView(chip)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func chipView(_ chip: Chip) -> some View {
        let isSelected = (chip == selectedChip)

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.92)) {
                selectedChip = chip
            }
        } label: {
            Text(chip.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : UIStyle.Colors.inkPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? UIStyle.Colors.accent : UIStyle.Colors.mutedFill)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? UIStyle.Colors.accent.opacity(0.35) : UIStyle.Colors.cardStroke, lineWidth: 1)
                )
                .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(chip.title))
        .accessibilityValue(Text(isSelected ? "Selected" : "Not selected"))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func onboardingContent(for chip: Chip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(chip.onboardingTitle)
                .font(.headline)
                .foregroundStyle(UIStyle.Colors.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(chip.onboardingLines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .foregroundStyle(UIStyle.Colors.inkSecondary)

                        Text(line)
                            .foregroundStyle(UIStyle.Colors.inkPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.callout)
                }
            }
        }
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
