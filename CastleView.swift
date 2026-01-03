import SwiftUI

struct CastleView: View {
    @EnvironmentObject private var store: GameStore

    // 022B constants (some will be overridden by 022D sizing inside GeometryReader)
    private let castleHorizontalPadding: CGFloat = 16

    // These are retained for general spacing; visual stroke/radius updated below per 022D
    private let gridOuterCornerRadius: CGFloat = 18
    private let gridInnerPadding: CGFloat = 10
    private let gridSpacing: CGFloat = 8
    private let gridAspect: CGFloat = 1.25 // height = width * 1.25

    // 022C helpers
    @ViewBuilder
    private func castleModePill(_ mode: GameStore.CastleMode) -> some View {
        let isActive = (store.castleMode == mode)

        Button(mode.rawValue) {
            store.setCastleMode(mode)
        }
        .font(.system(size: 14, weight: .semibold))
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(isActive ? Color.primary.opacity(0.10) : Color.secondary.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(isActive ? Color.primary.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private func tileEmoji(_ t: GameStore.CastleTile) -> String {
        t.building?.emoji ?? "⬜️"
    }

    private func tileTitle(_ t: GameStore.CastleTile) -> String {
        t.building?.title ?? "Empty"
    }

    private func tileStat(_ t: GameStore.CastleTile) -> String {
        guard let b = t.building else { return "Tap to build" }
        let lvl = max(1, t.level)
        let income = b.baseIncomePerDay * lvl
        return "+\(income)/day"
    }

    private func tileLevel(_ t: GameStore.CastleTile) -> String {
        guard t.building != nil else { return "—" }
        return "Lv \(max(1, t.level))"
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header — статус замка
            HStack {
                Text("Best: \(store.meta.bestFloor)")
                Spacer()
                Text("Day: \(store.meta.days)")
                Spacer()
                Text("+\(store.meta.incomePerDay) / day")
            }
            .font(.caption)

            // Верхний информационный блок (3 колонки)
            HStack(alignment: .top, spacing: 12) {
                // Левая колонка — экономика (wired to store)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buildings: \(store.castleBuildingsCount)")
                    Text("Income: +\(store.castleIncomePerDay)/day")
                    Text("Free tiles: \(store.castleFreeTilesCount)")
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Центр — плейсхолдер замка
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thinMaterial)
                    .frame(height: 120)
                    .overlay(
                        Text("Castle Image")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    )
                    .frame(maxWidth: .infinity)

                // Правая колонка — реликвии (stub icons for now)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Relics")
                        .font(.caption)
                        .fontWeight(.semibold)

                    HStack(spacing: 4) {
                        Text("🗿")
                        Text("🗝️")
                        Text("—")
                    }
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Режимные кнопки (пиллы)
            HStack(spacing: 10) {
                castleModePill(.build)
                castleModePill(.upgrade)
                castleModePill(.artifacts)
            }
            .padding(.top, 6)

            // Новый контейнер-грид 5×5 с масштабированием 022D
            GeometryReader { geo in
                // content width matches the info/relics content width
                let usableWidth = geo.size.width - (castleHorizontalPadding * 2)
                let usableHeight = geo.size.height

                // Scale targets:
                // - width +5%
                // - height +15%
                let gridWidth = usableWidth * 1.05
                let gridHeight = min(usableHeight, (usableWidth * gridAspect) * 1.15)

                // 1.2 Safe cell sizing from scaled container
                let cols: CGFloat = 5
                let rows: CGFloat = 5

                let innerPadding: CGFloat = 14 // increased to let content breathe
                let cellSpacing: CGFloat = 10   // slightly larger spacing

                let innerW = gridWidth - innerPadding * 2
                let innerH = gridHeight - innerPadding * 2

                let cellWidth = (innerW - cellSpacing * (cols - 1)) / cols
                let cellHeight = (innerH - cellSpacing * (rows - 1)) / rows

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    // GRID контейнер with increased radius and stroke width
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1.5)
                        )
                        .frame(width: gridWidth, height: gridHeight)
                        .overlay(
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: cellSpacing), count: Int(cols)),
                                spacing: cellSpacing
                            ) {
                                ForEach(store.castleTiles) { tile in
                                    CastleTileButton(
                                        emoji: tileEmoji(tile),
                                        title: tileTitle(tile),
                                        statLine: tileStat(tile),
                                        levelLine: tileLevel(tile),
                                        width: cellWidth,
                                        height: cellHeight
                                    ) {
                                        store.handleCastleTileTap(tile.id)
                                    }
                                }
                            }
                            .padding(innerPadding)
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)

                    Spacer(minLength: 12)

                    Button("Back to Hub") {
                        store.goToHub()
                    }
                    .padding(.bottom, 8)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
            .padding(.horizontal, 0)
        }
        .padding(.horizontal, castleHorizontalPadding)
        .padding(.vertical, 12)
    }
}

// Компонент плитки (UI-only) — 022D reflow and sizing
private struct CastleTileButton: View {
    let emoji: String
    let title: String
    let statLine: String
    let levelLine: String
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    var body: some View {
        // Scaled paddings and typography for 022D
        let pad: CGFloat = max(8, min(12, width * 0.08))
        let iconBoxH: CGFloat = max(18, min(24, height * 0.22))
        let titleSize: CGFloat = max(11, min(13, width * 0.12))
        let statSize: CGFloat = max(9,  min(11, width * 0.10))
        let levelSize: CGFloat = max(9, min(11, width * 0.10))
        let lineSpacing: CGFloat = 2

        return Button(action: onTap) {
            VStack(spacing: 6) {
                // Compact icon container
                Text(emoji)
                    .frame(height: iconBoxH)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Title
                Text(title)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Stat line
                Text(statLine)
                    .font(.system(size: statSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Level badge
                Text(levelLine)
                    .font(.system(size: levelSize, weight: .semibold))
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(pad)
            .frame(width: width, height: height)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
