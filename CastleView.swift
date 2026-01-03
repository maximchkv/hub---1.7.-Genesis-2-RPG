import SwiftUI

struct CastleView: View {
    @EnvironmentObject private var store: GameStore

    // 022B constants
    private let castleHorizontalPadding: CGFloat = 16
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

            // Новый контейнер-грид 5×5 с фиксированной геометрией
            GeometryReader { geo in
                let contentWidth = geo.size.width - (castleHorizontalPadding * 2)
                let outerWidth = contentWidth
                let outerHeight = outerWidth * gridAspect

                // 5 колонок, расстояния и внутренние отступы фиксированные
                let cellWidth = (outerWidth - (gridInnerPadding * 2) - (gridSpacing * 4)) / 5
                let cellHeight = cellWidth * gridAspect

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    // GRID контейнер
                    RoundedRectangle(cornerRadius: gridOuterCornerRadius)
                        .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                        .frame(width: outerWidth, height: outerHeight)
                        .overlay(
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gridSpacing), count: 5),
                                spacing: gridSpacing
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
                            .padding(gridInnerPadding)
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

// Компонент плитки (UI-only)
private struct CastleTileButton: View {
    let emoji: String
    let title: String
    let statLine: String
    let levelLine: String
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)

                Text(statLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)

                Text(levelLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .frame(width: width, height: height)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
