import SwiftUI
import Foundation

struct TowerView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showRunDeck: Bool = false

    // MARK: - Layout constants
    private let contentCap: CGFloat = 420
    
    // Стандартизированные отступы через UI Kit
    private let topPad: CGFloat = UIStyle.Spacing.s
    private let metaToMap: CGFloat = UIStyle.Spacing.m
    
    // Debug mode - set to true to see layout boundaries
    private let debugMode: Bool = false

    var body: some View {
        UIStyle.Layout.ScreenContainer {
            GeometryReader { geo in
                let contentWidth = min(geo.size.width - UIStyle.Spacing.xl * 2, contentCap)
                let totalHeight = geo.size.height
                
                // Расчёт высоты карты: geo.size — это всё пространство внутри safe area
                let headerHeight: CGFloat = 40
                let metaHeight: CGFloat = 70
                let spacings = topPad + metaToMap
                let usedHeight = headerHeight + metaHeight + spacings
                let mapHeight = max(200, totalHeight - usedHeight)
                
                ZStack(alignment: .top) {
                    // Debug: full geo area (yellow)
                    if debugMode {
                        Rectangle()
                            .stroke(Color.yellow, lineWidth: 2)
                            .frame(width: geo.size.width, height: totalHeight)
                    }
                    
                    VStack(spacing: 0) {
                        // Header
                        headerRow
                            .frame(width: contentWidth)
                            .padding(.top, topPad)
                            .modifier(DebugBorder(color: .blue, enabled: debugMode, label: "header"))
                        
                        Spacer().frame(height: metaToMap)
                        
                        // HP и прогресс
                        topInfoRow
                            .frame(width: contentWidth)
                            .modifier(DebugBorder(color: .orange, enabled: debugMode, label: "meta"))
                        
                        Spacer().frame(height: metaToMap)
                        
                        // Стратегическая карта (растянута до низа geo)
                        strategicMapSection(contentWidth: contentWidth, mapHeight: mapHeight)
                            .modifier(DebugBorder(color: .red, enabled: debugMode, label: "map h=\(Int(mapHeight))"))
                    }
                    .frame(width: geo.size.width, height: totalHeight, alignment: .top)
                    .modifier(DebugBorder(color: .green, enabled: debugMode, label: "content h=\(Int(totalHeight))"))
                }
                .frame(width: geo.size.width, height: totalHeight)
            }
        }
        .onAppear {
            if store.run?.towerMap == nil {
                store.refreshRoomOptions()
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            Button {
                store.goToHub()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(UIStyle.Colors.textPrimary)
                    .padding(6)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
                    .accessibilityLabel("Back to Hub")
            }
            .buttonStyle(.plain)

            Text("Башня")
                .font(.subheadline)
                .foregroundStyle(UIStyle.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            Button {
                showRunDeck = true
            } label: {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(UIStyle.Colors.textPrimary)
                    .padding(6)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
                    .accessibilityLabel("Колода забега")
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showRunDeck) {
            RunDeckView()
                .environmentObject(store)
        }
    }

    // MARK: - Meta

    private var topInfoRow: some View {
        HStack(alignment: .top, spacing: 12) {
            playerInfoRow
                .frame(maxWidth: .infinity, alignment: .leading)
            progressRow
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var playerInfoRow: some View {
        let hp = store.run?.playerHP ?? 0
        let maxHP = store.run?.playerMaxHP ?? 0
        let denom = max(1, maxHP)
        let hpFrac = Double(max(0, min(hp, denom))) / Double(denom)

        let hpColor: Color = {
            if hpFrac > 0.6 { return UIStyle.Colors.hpGreen }
            if hpFrac > 0.3 { return UIStyle.Colors.threatOrange }
            return UIStyle.Colors.threatRed
        }()

        return metaCard(vertical: 8, horizontal: 12) {
            VStack(spacing: 10) {
                HStack {
                    Text("Здоровье")
                        .font(.caption)
                        .foregroundStyle(Color.black)
                    Spacer(minLength: 0)
                    Text("\(hp)/\(maxHP)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(hpColor)
                }

                TowerHPBar(fraction: hpFrac, color: hpColor)
                    .frame(height: 10)
            }
            .frame(minHeight: 48)
        }
        .accessibilityLabel("Здоровье \(hp) из \(maxHP).")
    }

    private var progressRow: some View {
        let floorInAct = store.run?.floorInAct ?? 0
        let bossIn = store.run?.floorsRemainingToBoss ?? 0
        let global = store.run?.globalFloor ?? 0
        let globalTotal = store.run?.globalFloorsTotal ?? 0

        return metaCard(vertical: 8, horizontal: 12) {
            HStack(spacing: 12) {
                metaChip(title: "Этаж", value: "\(floorInAct)/\(RunState.floorsPerAct + 1)")
                    .frame(maxWidth: .infinity)

                metaChip(title: "Босс", value: "\(bossIn)")
                    .frame(maxWidth: .infinity)

                metaChip(title: "Всего", value: "\(global)/\(globalTotal)")
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 48)
        }
        .accessibilityLabel("Этаж \(floorInAct). До босса \(bossIn). Всего \(global) из \(globalTotal).")
    }

    private func metaChip(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.black.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .center)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(minWidth: 0)
    }

    private func metaCard<Content: View>(
        vertical: CGFloat = 12,
        horizontal: CGFloat = 12,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        content()
            .padding(.vertical, vertical)
            .padding(.horizontal, horizontal)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
    }

    // MARK: - Strategic Map Section (Full Height)
    
    private func strategicMapSection(contentWidth: CGFloat, mapHeight: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            // Map view - растянут на всю доступную высоту
            StrategicMapView()
                .frame(width: contentWidth)
                .frame(height: mapHeight)
            
            // Legend overlay
            MapLegendView()
                .padding(8)
        }
        .background(
            ZStack {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.thinMaterial)
                Color.white.opacity(0.9)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.26), lineWidth: 1)
        )
    }
}

// MARK: - Debug Border Modifier

private struct DebugBorder: ViewModifier {
    let color: Color
    let enabled: Bool
    let label: String
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .overlay(
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .stroke(color, lineWidth: 1)
                        Text(label)
                            .font(.system(size: 8))
                            .foregroundColor(color)
                            .padding(2)
                            .background(Color.black.opacity(0.7))
                    }
                )
        } else {
            content
        }
    }
}

// MARK: - Local helpers

private struct TowerHPBar: View {
    let fraction: Double
    let color: Color
    
    init(fraction: Double, color: Color = UIStyle.Colors.hpGreen) {
        self.fraction = fraction
        self.color = color
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let f = max(0, min(1, fraction))
            let fillW = CGFloat(f) * w

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
                    .frame(width: fillW)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .accessibilityHidden(true)
    }
}
