import SwiftUI

// MARK: - Figma Start Screen (Light Theme)
// Спецификация: https://www.figma.com/design/PEq2dxbhb98coh6aHH2mRV — node 1:58

struct StartView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private let subtitle = "A parchment roguelike of cards, climbs, and a living castle."

    @State private var selectedChip: Chip = .collect

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

        var icon: Image {
            switch self {
            case .climb: return Image(systemName: "figure.climbing")
            case .cards: return Image(systemName: "rectangle.stack.fill")
            case .castle: return Image(systemName: "building.columns.fill")
            case .collect: return Image(systemName: "diamond.fill")
            }
        }

        var onboardingLines: [String] {
            switch self {
            case .climb:
                return [
                    "Find rewards and adapt your build.",
                    "Survive to reach the next floor.",
                    "Choose routes and face encounters."
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

    // Figma color palette (light theme)
    private enum Figma {
        static let bgTop = Color(red: 0.94, green: 0.95, blue: 0.97)
        static let bgBottom = Color(red: 1.0, green: 1.0, blue: 1.0)
        static let textDark = Color(red: 0.25, green: 0.27, blue: 0.32)
        static let textLight = Color(red: 0.55, green: 0.58, blue: 0.65)
        static let railBg = Color(red: 0.96, green: 0.97, blue: 0.98)
        static let cardBg = Color(red: 0.96, green: 0.97, blue: 0.98)
        static let activeSegmentBg = Color(red: 0.45, green: 0.50, blue: 0.58)
        static let ctaGradientTop = Color(red: 0.45, green: 0.50, blue: 0.58)
        static let ctaGradientBottom = Color(red: 0.35, green: 0.39, blue: 0.45)
        static let debugButtonBg = Color(red: 0.94, green: 0.95, blue: 0.97)
        static let debugButtonBorder = Color(red: 0.88, green: 0.90, blue: 0.92)
        static let iconAccent = Color(red: 0.40, green: 0.45, blue: 0.55)
        static let shadowColor = Color.black.opacity(0.08)
        static let shadowColorStrong = Color.black.opacity(0.15)
    }

    var body: some View {
        GeometryReader { geo in
            let horizontalPadding: CGFloat = 24
            let contentWidth = min(360, max(0, geo.size.width - horizontalPadding * 2))

            ZStack {
                LinearGradient(
                    colors: [Figma.bgTop, Figma.bgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ViewThatFits(in: .vertical) {
                    nonScrollLayout(contentWidth: contentWidth)
                    scrollLayout(contentWidth: contentWidth)
                }
            }
        }
    }

    private func nonScrollLayout(contentWidth: CGFloat) -> some View {
        contentBlock(contentWidth: contentWidth)
            .padding(.horizontal, 24)
            .padding(.vertical, UIStyle.Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func scrollLayout(contentWidth: CGFloat) -> some View {
        ScrollView(.vertical) {
            HStack {
                Spacer(minLength: 0)
                contentBlock(contentWidth: contentWidth)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, UIStyle.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }

    private func contentBlock(contentWidth: CGFloat) -> some View {

        return VStack(spacing: 24) {
            // Header: Title + subtitle (Figma: bold dark gray sans-serif, light gray subtitle)
            VStack(spacing: 8) {
                Text("Tower of Ink")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(Figma.textDark)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(subtitle)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundStyle(Figma.textLight)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            // Figma: Segmented control — light gray rail, blue-gray active, white text on active
            figmaSegmentedControl(contentWidth: contentWidth)

            // Figma: Info card — light gray bg, dark gray header + icon, light gray bullets
            VStack(alignment: .leading, spacing: 12) {
                onboardingContent(for: selectedChip)
                    .id(selectedChip)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        )
                    )
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Figma.cardBg)
            )
            .shadow(color: Figma.shadowColor, radius: 8, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.22), value: selectedChip)

            // Figma: Start Run — полноценная кнопка с градиентом и отдачей при нажатии
            Button {
                store.startRun()
            } label: {
                Text("Start Run")
                    .font(.system(size: 17, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(StartRunButtonStyle())

            // Figma: Debug — light gray rect, thin border, light gray text
            Button {
                store.debugStartFirstBattle()
            } label: {
                Text("DEBUG: First Battle")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundStyle(Figma.textLight)
                    .frame(height: 36)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Figma.debugButtonBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Figma.debugButtonBorder, lineWidth: 1)
                            )
                    )
            }
            .shadow(color: Figma.shadowColor, radius: 4, x: 0, y: 1)
            .buttonStyle(.plain)
        }
        .frame(width: contentWidth)
    }

    // Figma segmented control: light rail, inactive = dark text, active = blue-gray bg + white text
    private func figmaSegmentedControl(contentWidth: CGFloat) -> some View {
        let railHeight: CGFloat = 44

        return ZStack {
            // Rail background
            RoundedRectangle(cornerRadius: railHeight / 2, style: .continuous)
                .fill(Figma.railBg)
                .shadow(color: Figma.shadowColor, radius: 6, x: 0, y: 2)

            GeometryReader { geo in
                let count = CGFloat(Chip.allCases.count)
                let segmentWidth = geo.size.width / count

                ZStack(alignment: .leading) {
                    // Active segment capsule (blue-gray)
                    RoundedRectangle(cornerRadius: (railHeight - 8) / 2, style: .continuous)
                        .fill(Figma.activeSegmentBg)
                        .shadow(color: Figma.shadowColor, radius: 4, x: 0, y: 2)
                        .frame(width: segmentWidth - 8, height: railHeight - 8)
                        .padding(4)
                        .offset(x: segmentOffset(for: segmentWidth))
                        .animation(.easeInOut(duration: 0.22), value: selectedChip)

                    HStack(spacing: 0) {
                        ForEach(Chip.allCases) { chip in
                            let isActive = chip == selectedChip
                            Button {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    selectedChip = chip
                                }
                            } label: {
                                Label {
                                    Text(chip.title)
                                } icon: {
                                    chip.icon
                                }
                                .font(.system(size: 14, weight: .semibold, design: .default))
                                .labelStyle(.titleAndIcon)
                                .foregroundStyle(isActive ? .white : Figma.textDark)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(width: contentWidth)
        .frame(height: railHeight)
    }

    private func segmentOffset(for segmentWidth: CGFloat) -> CGFloat {
        guard let idx = Chip.allCases.firstIndex(of: selectedChip) else { return 0 }
        return CGFloat(idx) * segmentWidth + 4
    }

    private func onboardingContent(for chip: Chip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Figma.iconAccent)
                Text(chip.onboardingTitle)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundStyle(Figma.textDark)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(chip.onboardingLines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Figma.textDark)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(line)
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundStyle(Figma.textLight)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

// MARK: - Стиль кнопки Start Run
private struct StartRunButtonStyle: ButtonStyle {
    private enum Figma {
        static let ctaGradientTop = Color(red: 0.45, green: 0.50, blue: 0.58)
        static let ctaGradientBottom = Color(red: 0.35, green: 0.39, blue: 0.45)
        static let shadowColorStrong = Color.black.opacity(0.15)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Figma.ctaGradientTop, Figma.ctaGradientBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: Figma.shadowColorStrong, radius: 12, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
