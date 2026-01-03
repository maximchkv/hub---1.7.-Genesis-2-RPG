import SwiftUI

struct CastleView: View {
    @EnvironmentObject private var store: GameStore

    // Local state: Build (022E) and Upgrade (022F) overlays
    @State private var isBuildPickerPresented: Bool = false
    @State private var buildPickerTileIndex: Int? = nil

    @State private var isUpgradePickerPresented: Bool = false
    @State private var upgradePickerTileIndex: Int? = nil

    // 022G: local interaction mode used only for highlighting
    private enum CastleInteractionMode {
        case build
        case upgrade
    }
    @State private var mode: CastleInteractionMode = .build

    // Layout constants (from 022D)
    private let castleHorizontalPadding: CGFloat = 16
    private let gridAspect: CGFloat = 1.25 // height = width * 1.25

    // 022H: Mode button helper
    private func modePill(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(minWidth: 92)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? Color.white : Color.accentColor)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color.accentColor : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentColor.opacity(isActive ? 0.0 : 0.35), lineWidth: 1.5)
        )
        .background(
            // subtle base for inactive
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color.clear : Color.black.opacity(0.04))
        )
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
                // Левая колонка — экономика
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

            // Режимные кнопки — only highlight (not behavior)
            HStack(spacing: 12) {
                modePill("Build", isActive: mode == .build) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        mode = .build
                    }
                }

                modePill("Upgrade", isActive: mode == .upgrade) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        mode = .upgrade
                    }
                }
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
                                    let isEmpty = (tile.building == nil)
                                    let isUpg = (tile.building != nil)
                                    let isHighlighted = (mode == .build && isEmpty) || (mode == .upgrade && isUpg)

                                    Button {
                                        // 022G: auto action by tile state
                                        if isEmpty {
                                            buildPickerTileIndex = tile.id
                                            isBuildPickerPresented = true
                                            return
                                        }
                                        if isUpg {
                                            upgradePickerTileIndex = tile.id
                                            isUpgradePickerPresented = true
                                            return
                                        }
                                    } label: {
                                        CastleTileContentView(
                                            iconText: tile.building?.emoji ?? "⬜️",
                                            titleText: tile.building?.title ?? "Empty",
                                            statText: tile.building == nil
                                                ? "Tap to build"
                                                : "+\((tile.building?.baseIncomePerDay ?? 0) * max(1, tile.level))/day",
                                            levelText: tile.building == nil ? "—" : "Lv \(max(1, tile.level))",
                                            width: cellWidth,
                                            height: cellHeight
                                        )
                                        // Highlight overlay + animation
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isHighlighted ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 2)
                                                .animation(.easeInOut(duration: 0.18), value: isHighlighted)
                                        )
                                        .opacity(isHighlighted ? 1.0 : 0.92)
                                        .scaleEffect(isHighlighted ? 1.0 : 0.995)
                                        .animation(.spring(response: 0.22, dampingFraction: 0.9), value: isHighlighted)
                                        .animation(.spring(response: 0.22, dampingFraction: 0.9), value: mode)
                                    }
                                    .buttonStyle(.plain)
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
        // Overlays: Build (022E) and Upgrade (022F)
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

            if isUpgradePickerPresented, let idx = upgradePickerTileIndex,
               let info = store.castleTileInfo(idx) {
                UpgradePickerOverlay(
                    title: info.title,
                    icon: info.icon,
                    currentLevel: info.level,
                    incomePerDay: info.incomePerDay,
                    onUpgrade: {
                        store.upgradeTile(index: idx)
                        isUpgradePickerPresented = false
                        upgradePickerTileIndex = nil
                    },
                    onCancel: {
                        isUpgradePickerPresented = false
                        upgradePickerTileIndex = nil
                    }
                )
            }
        }
    }
}

// MARK: - Polished tile content view (022G)
private struct CastleTileContentView: View {
    let iconText: String
    let titleText: String
    let statText: String
    let levelText: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let pad: CGFloat = max(8, min(12, width * 0.08))
        let iconBlockH: CGFloat = max(44, min(56, height * 0.38))
        let statSize: CGFloat = max(9,  min(11, width * 0.10))
        let levelSize: CGFloat = max(9, min(11, width * 0.10))

        return VStack(spacing: 6) {
            // Bigger icon + title block with darker background
            VStack(spacing: 4) {
                Text(iconText)
                    .font(.system(size: 20))

                Text(titleText)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: iconBlockH)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.08))
            )

            // Stat line
            Text(statText)
                .font(.system(size: statSize))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Level “merged” with button (no separate filled background)
            Text(levelText)
                .font(.system(size: levelSize, weight: .semibold))
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .foregroundStyle(.secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
        .padding(pad)
        .frame(width: width, height: height)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
