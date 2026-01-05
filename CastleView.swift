import SwiftUI

struct CastleView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    // Relics sheet state (022J)
    @State private var isRelicsSheetPresented: Bool = false

    // Layout constants
    private let gridAspect: CGFloat = 1.25 // height = width * 1.25

    // Width cap helper (028B)
    private func widthCap(for sizeClass: UserInterfaceSizeClass?, windowWidth: CGFloat) -> CGFloat {
        switch sizeClass {
        case .compact:
            return 360
        case .regular:
            return windowWidth < 900 ? 600 : 720
        default:
            return 360
        }
    }

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
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color.clear : Color.black.opacity(0.04))
        )
    }

    var body: some View {
        ZStack {
            UIStyle.background()
                .ignoresSafeArea()

            // Existing content (unchanged)
            GeometryReader { geo in
                ScrollView {
                    let horizontalPadding: CGFloat = 24
                    let availableWidth = max(0, geo.size.width - horizontalPadding * 2)
                    let cap = widthCap(for: hSizeClass, windowWidth: geo.size.width)
                    let contentWidth = min(availableWidth, cap)

                    HStack(spacing: 0) {
                        Spacer(minLength: 0)

                        VStack(spacing: 12) {
                            // Header — bottom divider + clamp to contentWidth
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Best: \(store.meta.bestFloor)")
                                        .lineLimit(1).minimumScaleFactor(0.85)
                                    Spacer()
                                    Text("Day: \(store.meta.days)")
                                        .lineLimit(1).minimumScaleFactor(0.85)
                                    Spacer()
                                    Text("+\(store.castleIncomePerDay) / day")
                                        .lineLimit(1).minimumScaleFactor(0.85)
                                }
                                .font(.caption)
                                .padding(.horizontal)
                                .padding(.vertical, 10)

                                Rectangle()
                                    .fill(Color.primary.opacity(0.12))
                                    .frame(height: 1)
                            }
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .frame(width: contentWidth, alignment: .center)

                            // Top block with computed fixed widths per contentWidth
                            let imageBox: CGFloat = 120
                            let gap: CGFloat = 12
                            let rightCol: CGFloat = 70
                            let leftCol: CGFloat = max(120, contentWidth - imageBox - rightCol - gap*2)

                            // REPLACED: three-column symmetric HStack (center fixed width)
                            HStack(alignment: .top, spacing: 12) {

                                // LEFT (stats)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Buildings: \(store.castleBuildingsCount)")
                                    Text("Income: +\(store.castleIncomePerDay)/day")
                                    Text("Free tiles: \(store.castleFreeTilesCount)")
                                }
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // CENTER (castle image placeholder) — всегда по центру
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.thinMaterial)
                                        .overlay(
                                            VStack(spacing: 6) {
                                                Text("🏰")
                                                    .font(.title2)
                                                Text("Castle Image")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                                        )
                                        .frame(width: 140, height: 110)
                                }
                                .frame(width: 140)

                                // RIGHT (relics)
                                VStack(alignment: .trailing, spacing: 6) {
                                    Button {
                                        isRelicsSheetPresented = true
                                    } label: {
                                        VStack(alignment: .trailing, spacing: 6) {
                                            Text("Relics")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                            HStack(spacing: 6) {
                                                Text("🗿")
                                                Text("🗝️")
                                                Text("—")
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .frame(width: contentWidth, alignment: .center)

                            // Mode buttons — store-driven with toggle idle behavior
                            HStack(spacing: 12) {
                                modePill("Build", isActive: store.castleModeUI == CastleUIMode.build) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                        store.setCastleMode(CastleUIMode.build)
                                    }
                                }

                                modePill("Upgrade", isActive: store.castleModeUI == CastleUIMode.upgrade) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                        store.setCastleMode(CastleUIMode.upgrade)
                                    }
                                }
                            }
                            .frame(width: contentWidth, alignment: .center)

                            #if DEBUG
                            Button("Next Day (debug)") {
                                store.castleAdvanceDay()
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 6)
                            .frame(width: contentWidth, alignment: .center)
                            #endif

                            // Grid container (derived from contentWidth)
                            let gridWidth = contentWidth
                            let gridHeight = gridWidth * gridAspect

                            // Derived cell sizing
                            let cols: CGFloat = 5
                            let rows: CGFloat = 5
                            let innerPadding: CGFloat = 14
                            let cellSpacing: CGFloat = 10

                            let innerW = gridWidth - innerPadding * 2
                            let innerH = gridHeight - innerPadding * 2

                            let cellWidth = (innerW - cellSpacing * (cols - 1)) / cols
                            let cellHeight = (innerH - cellSpacing * (rows - 1)) / rows

                            VStack(spacing: 0) {
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
                                                let isMaxLevel: Bool = {
                                                    if case .built(let type, let level) = tile.state {
                                                        return level >= type.maxLevel
                                                    }
                                                    return false
                                                }()

                                                let isEmpty = (tile.building == nil)
                                                let isHighlighted: Bool = {
                                                    switch store.castleModeUI {
                                                    case CastleUIMode.build: return isEmpty
                                                    case CastleUIMode.upgrade:
                                                        return !isEmpty && !isMaxLevel
                                                    case CastleUIMode.idle: return false
                                                    }
                                                }()

                                                Button {
                                                    store.onTileTapped(tile)
                                                } label: {
                                                    CastleTileContentView(
                                                        iconText: tile.building?.emoji ?? "⬜️",
                                                        titleText: tile.building?.title ?? "Empty",
                                                        statText: tile.building == nil
                                                            ? "Tap to build"
                                                            : "+\((tile.building?.incomePerDay(level: max(1, tile.level)) ?? 0))/day",
                                                        levelText: {
                                                            if tile.building == nil { return "—" }
                                                            return isMaxLevel ? "MAX" : "Lv \(max(1, tile.level))"
                                                        }(),
                                                        width: cellWidth,
                                                        height: cellHeight
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(isHighlighted ? Color.accentColor.opacity(0.9) : Color.clear, lineWidth: 3)
                                                    )
                                                    .opacity({
                                                        switch store.castleModeUI {
                                                        case CastleUIMode.build:
                                                            return (tile.building != nil) ? 0.35 : 1.0
                                                        case CastleUIMode.upgrade:
                                                            if tile.building == nil { return 0.35 }
                                                            return isMaxLevel ? 0.35 : 1.0
                                                        case CastleUIMode.idle:
                                                            return 1.0
                                                        }
                                                    }())
                                                    .scaleEffect(isHighlighted ? 1.02 : 1.0)
                                                }
                                                .buttonStyle(.plain)
                                                .allowsHitTesting({
                                                    switch store.castleModeUI {
                                                    case CastleUIMode.build:
                                                        return isEmpty
                                                    case CastleUIMode.upgrade:
                                                        return (!isEmpty && !isMaxLevel)
                                                    case CastleUIMode.idle:
                                                        return true
                                                    }
                                                }())
                                            }
                                        }
                                        .padding(innerPadding)
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)

                                // Back to Hub
                                Button("Back to Hub") {
                                    store.goToHub()
                                }
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.top, 12)
                        .padding(.bottom, 18)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, horizontalPadding)
                }
                .scrollIndicators(.hidden)
            }
            .onAppear {
                store.castleRecomputeStats()
            }
            .sheet(isPresented: $isRelicsSheetPresented) {
                RelicsListSheetView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $store.isBuildSheetPresented) {
                CastleBuildSheetView(
                    onPickFarm: {
                        if let farm = store.buildCandidates.first(where: { $0.kind == .farm }) {
                            store.confirmBuild(farm)
                        } else {
                            store.confirmBuild(
                                BuildCandidate(kind: .farm, title: "Farm", emoji: "🌾", incomePerDay: 1, blurb: "+1 / day")
                            )
                        }
                    },
                    onPickMine: {
                        if let mine = store.buildCandidates.first(where: { $0.kind == .mine }) {
                            store.confirmBuild(mine)
                        } else {
                            store.confirmBuild(
                                BuildCandidate(kind: .mine, title: "Mine", emoji: "⛏️", incomePerDay: 2, blurb: "+2 / day")
                            )
                        }
                    },
                    onClose: {
                        store.cancelBuildSheet()
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $store.isUpgradeSheetPresented) {
                if let idx = store.selectedCastleTileIndex,
                   let info = store.castleTileInfo(idx) {
                    CastleUpgradeSheetView(
                        title: info.title,
                        icon: info.icon,
                        levelText: "Lv \(info.level)",
                        incomeText: "+\(info.incomePerDay)/day",
                        onUpgrade: {
                            store.upgradeTile(tileIndex: idx)
                            store.closeUpgradeSheet()
                        },
                        onClose: {
                            store.closeUpgradeSheet()
                        }
                    )
                    .presentationDetents([.medium])
                } else {
                    Color.clear
                        .onAppear { store.closeUpgradeSheet() }
                }
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

            Text(statText)
                .font(.system(size: statSize))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

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

// 023C: Simple Build sheet UI (Farm / Mine)
private struct CastleBuildSheetView: View {
    let onPickFarm: () -> Void
    let onPickMine: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Build")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                Button {
                    onPickFarm()
                    onClose()
                } label: {
                    HStack(spacing: 12) {
                        Text("🌾").font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Farm").font(.headline)
                            Text("+ income/day (stub)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button {
                    onPickMine()
                    onClose()
                } label: {
                    HStack(spacing: 12) {
                        Text("⛏️").font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mine").font(.headline)
                            Text("+ income/day (stub)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Button("Close") {
                onClose()
            }
            .padding(.top, 4)
        }
        .padding(20)
    }
}

// 023E: Minimal Upgrade sheet UI
private struct CastleUpgradeSheetView: View {
    let title: String
    let icon: String
    let levelText: String
    let incomeText: String

    let onUpgrade: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Upgrade")
                .font(.title2)

            HStack(spacing: 12) {
                Text(icon)
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text("\(incomeText) • \(levelText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            Button("Upgrade (stub)") {
                onUpgrade()
            }
            .buttonStyle(.borderedProminent)

            Button("Close") {
                onClose()
            }
        }
        .padding()
    }
}
