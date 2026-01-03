import SwiftUI

struct CastleView: View {
    @EnvironmentObject private var store: GameStore

    // Relics sheet state (022J)
    @State private var isRelicsSheetPresented: Bool = false

    // Layout constants
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
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color.clear : Color.black.opacity(0.04))
        )
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                // Fixed-width wrapper centered via contentWidth
                let contentWidth = min(geo.size.width - 32, 520)

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
                            Text("+\(store.meta.incomePerDay) / day")
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

                        // RIGHT (relics) — сохрани текущий контент/кликабельность
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
                    .padding(.top, 6)
                    .frame(width: contentWidth, alignment: .center)

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
                                        let isEmpty = (tile.building == nil)
                                        let isHighlighted: Bool = {
                                            switch store.castleModeUI {
                                            case CastleUIMode.build: return isEmpty
                                            case CastleUIMode.upgrade: return !isEmpty
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
                                                    : "+\((tile.building?.baseIncomePerDay ?? 0) * max(1, tile.level))/day",
                                                levelText: tile.building == nil ? "—" : "Lv \(max(1, tile.level))",
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
                                                    return tile.canUpgrade ? 0.4 : 1.0
                                                case CastleUIMode.upgrade:
                                                    return tile.isEmpty ? 0.4 : 1.0
                                                case CastleUIMode.idle:
                                                    return 1.0
                                                }
                                            }())
                                        }
                                        .buttonStyle(.plain)
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
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
        }
        // Relics sheet
        .sheet(isPresented: $isRelicsSheetPresented) {
            RelicsListSheetView()
                .environmentObject(store)
        }
        // Build sheet (replaces "Build (stub)")
        .sheet(isPresented: $store.isBuildSheetPresented) {
            CastleBuildSheetView(
                onPickFarm: {
                    // TODO: hook real build later
                },
                onPickMine: {
                    // TODO: hook real build later
                },
                onClose: {
                    // Use existing close path for this sheet
                    store.closeBuildSheet()
                }
            )
            .presentationDetents([.medium])
        }
        // Upgrade sheet (unchanged)
        .sheet(isPresented: $store.isUpgradeSheetPresented) {
            VStack(spacing: 12) {
                Text("Upgrade (stub)")
                    .font(.title2)

                if let idx = store.selectedCastleTileIndex {
                    Text("Tile: \(idx)")
                        .font(.headline)
                }

                Button("Close") {
                    store.closeUpgradeSheet()
                }
                .padding(.top, 8)
            }
            .padding()
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
