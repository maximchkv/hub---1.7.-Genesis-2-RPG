import SwiftUI

struct CastleView: View {
    @EnvironmentObject private var store: GameStore

    // Local state for build picker overlay
    @State private var isBuildPickerPresented: Bool = false
    @State private var buildPickerTileIndex: Int? = nil

    // 022B constants (kept)
    private let castleHorizontalPadding: CGFloat = 16
    private let gridAspect: CGFloat = 1.25 // height = width * 1.25

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Best: \(store.meta.bestFloor)")
                Spacer()
                Text("Day: \(store.meta.days)")
                Spacer()
                Text("+\(store.meta.incomePerDay) / day")
            }
            .font(.caption)

            // Info block
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buildings: \(store.castleBuildingsCount)")
                    Text("Income: +\(store.castleIncomePerDay)/day")
                    Text("Free tiles: \(store.castleFreeTilesCount)")
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)

                RoundedRectangle(cornerRadius: 16)
                    .fill(.thinMaterial)
                    .frame(height: 120)
                    .overlay(
                        Text("Castle Image")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    )
                    .frame(maxWidth: .infinity)

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

            // Mode pills
            HStack(spacing: 10) {
                castleModePill(.build)
                castleModePill(.upgrade)
                castleModePill(.artifacts)
            }
            .padding(.top, 6)

            // Grid container (sizing from 022D)
            GeometryReader { geo in
                let usableWidth = geo.size.width - (castleHorizontalPadding * 2)
                let usableHeight = geo.size.height

                let gridWidth = usableWidth * 1.05
                let gridHeight = min(usableHeight, (usableWidth * gridAspect) * 1.15)

                let cols: CGFloat = 5
                let rows: CGFloat = 5

                let innerPadding: CGFloat = 14
                let cellSpacing: CGFloat = 10

                let innerW = gridWidth - innerPadding * 2
                let innerH = gridHeight - innerPadding * 2

                let cellWidth = (innerW - cellSpacing * (cols - 1)) / cols
                let cellHeight = (innerH - cellSpacing * (rows - 1)) / rows

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

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
                                        // Open picker only on empty tile in Build mode
                                        if store.castleMode == .build, tile.building == nil {
                                            buildPickerTileIndex = tile.id
                                            isBuildPickerPresented = true
                                        } else {
                                            // Delegate to store for other behaviors
                                            store.handleCastleTileTap(tile.id)
                                        }
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
        // Overlay for build picker
        .overlay {
            if isBuildPickerPresented, let idx = buildPickerTileIndex {
                BuildPickerOverlay(
                    onSelectMine: {
                        store.buildOnTile(index: idx, kind: .mine)
                        isBuildPickerPresented = false
                        buildPickerTileIndex = nil
                    },
                    onSelectFarm: {
                        store.buildOnTile(index: idx, kind: .farm)
                        isBuildPickerPresented = false
                        buildPickerTileIndex = nil
                    },
                    onCancel: {
                        isBuildPickerPresented = false
                        buildPickerTileIndex = nil
                    }
                )
            }
        }
    }

    // 022C helpers (kept)
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
}

// Castle tile button with 022D reflow (unchanged here)
private struct CastleTileButton: View {
    let emoji: String
    let title: String
    let statLine: String
    let levelLine: String
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    var body: some View {
        let pad: CGFloat = max(8, min(12, width * 0.08))
        let iconBoxH: CGFloat = max(18, min(24, height * 0.22))
        let titleSize: CGFloat = max(11, min(13, width * 0.12))
        let statSize: CGFloat = max(9,  min(11, width * 0.10))
        let levelSize: CGFloat = max(9, min(11, width * 0.10))

        return Button(action: onTap) {
            VStack(spacing: 6) {
                Text(emoji)
                    .frame(height: iconBoxH)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(title)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(statLine)
                    .font(.system(size: statSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

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
