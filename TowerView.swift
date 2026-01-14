import SwiftUI

struct TowerView: View {
    @EnvironmentObject private var store: GameStore

    // MARK: - Layout constants (UI-KIT v1.0)
    private let contentCap: CGFloat = 380
    private let outerPad: CGFloat = 0

    private let topPad: CGFloat = 10
    private let toastToMeta: CGFloat = 12
    private let metaToRooms: CGFloat = 14

    // Toast
    private let toastHideDelay: Double = 1.2

    var body: some View {
        ZStack {
            UIStyle.background()
                .ignoresSafeArea()

            GeometryReader { geo in
                let available = max(0, geo.size.width - outerPad * 2)
                let contentWidth = min(available, contentCap)

                VStack(spacing: 0) {

                    // Header (только заголовок)
                    headerRow
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.top, topPad)

                    // Toast
                    toastView
                        .frame(width: contentWidth, alignment: .center)

                    Spacer().frame(height: toastToMeta)

                    // Top info — two columns (HP left, run progress right)
                    topInfoRow
                        .frame(width: contentWidth, alignment: .center)

                    Spacer().frame(height: metaToRooms)

                    roomsSection(contentWidth: contentWidth)
                        .frame(width: contentWidth, alignment: .center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .padding(.horizontal, outerPad)
            }
        }
        .onAppear {
            if store.run?.roomOptions.isEmpty ?? true {
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(8)
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    )
                    .accessibilityLabel("Back to Hub")
            }
            .buttonStyle(.plain)

            Text("Башня")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            // symmetric spacer so title stays centered
            Color.clear
                .frame(width: 34, height: 34)
        }
    }

    // MARK: - Toast

    private var toastView: some View {
        Group {
            if let toast = store.toast {
                Text(toast)
                    .font(.caption)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + toastHideDelay) {
                            if store.toast == toast {
                                store.toast = nil
                            }
                        }
                    }
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Meta

    private var topInfoRow: some View {
        HStack(alignment: .top, spacing: 12) {
            playerInfoRow
                .frame(maxWidth: .infinity)
            progressRow
                .frame(maxWidth: .infinity)
        }
    }

    private var playerInfoRow: some View {
        let hp = store.run?.playerHP ?? 0
        let maxHP = store.run?.playerMaxHP ?? 0
        let denom = max(1, maxHP)
        let hpFrac = Double(max(0, min(hp, denom))) / Double(denom)

        return metaCard(vertical: 10, horizontal: 12) {
            VStack(spacing: 8) {
                HStack {
                    Text("Здоровье")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text("\(hp)/\(maxHP)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                TowerHPBar(fraction: hpFrac)
                    .frame(height: 7)
            }
        }
        .accessibilityLabel("Здоровье \(hp) из \(maxHP).")
    }

    private var progressRow: some View {
        let floorInAct = store.run?.floorInAct ?? 0
        let bossIn = store.run?.floorsRemainingToBoss ?? 0
        let global = store.run?.globalFloor ?? 0
        let globalTotal = store.run?.globalFloorsTotal ?? 0

        return metaCard(vertical: 10, horizontal: 12) {
            HStack(spacing: 12) {
                metaChip(title: "Этаж", value: "\(floorInAct)/\(RunState.floorsPerAct + 1)")
                    .frame(maxWidth: .infinity)

                metaChip(title: "Босс", value: "\(bossIn)")
                    .frame(maxWidth: .infinity)

                metaChip(title: "Всего", value: "\(global)/\(globalTotal)")
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityLabel("Этаж \(floorInAct). До босса \(bossIn). Всего \(global) из \(globalTotal).")
    }

    private func metaChip(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
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

    // MARK: - Rooms

    private func roomsSection(contentWidth: CGFloat) -> some View {
        let options = store.run?.roomOptions ?? []
        // Larger container for bigger cards
        let containerHeight: CGFloat = {
            if options.isEmpty { return 280 }
            if options.count <= 3 { return 480 }
            return 600
        }()

        return VStack(spacing: 0) {
            Spacer(minLength: 8)
            roomsStage(options)
                .frame(width: contentWidth, alignment: .center)
                .frame(height: containerHeight)
            Spacer(minLength: 8)
        }
    }

    private func roomsStage(_ options: [RoomOption]) -> some View {
        // Intentionally NO background/border: this is a pure layout stage.
        VStack(spacing: 0) {
            Group {
                if options.isEmpty {
                    Text("Комнаты недоступны")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if options.count <= 3 {
                    // Even vertical distribution with tighter spacing
                    VStack(spacing: 12) {
                        ForEach(options) { option in
                            Button {
                                store.selectRoom(option)
                            } label: {
                                roomOptionCard(option)
                            }
                            .buttonStyle(.plain)
                            .disabled(option.isLocked)
                            .opacity(option.isLocked ? 0.55 : 1.0)
                        }
                    }
                } else {
                    ScrollView(.vertical) {
                        VStack(spacing: 12) {
                            ForEach(options) { option in
                                Button {
                                    store.selectRoom(option)
                                } label: {
                                    roomOptionCard(option)
                                }
                                .buttonStyle(.plain)
                                .disabled(option.isLocked)
                                .opacity(option.isLocked ? 0.55 : 1.0)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func roomOptionCard(_ option: RoomOption) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Portrait (left) — larger
            roomPortrait(option)
                .frame(width: 72, height: 72)
            
            // Center content
            VStack(alignment: .leading, spacing: 8) {
                // Top row: title + difficulty
                HStack(alignment: .center) {
                    Text(option.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    // Difficulty / safety indicator
                    if option.difficulty > 0 {
                        difficultyIndicator(option.difficulty)
                    } else {
                        safeIndicator(option.kind)
                    }
                }
                
                // Room type
                Text(option.kindDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                // Description
                if !option.descriptionText.isEmpty {
                    Text(option.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Locked subtitle
                if !option.subtitle.isEmpty {
                    Text(option.subtitle)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                        .lineLimit(2)
                }
            }
            
            // Trailing chevron
            if option.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(minHeight: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Room Portrait
    
    private func roomPortrait(_ option: RoomOption) -> some View {
        let cornerRadius: CGFloat = 14
        
        return ZStack {
            // Background with subtle gradient for depth
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // If we have an enemy preview, show their portrait
            if let enemy = option.previewEnemy, let assetName = enemyAssetName(enemy) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                // Fallback to icon for non-combat rooms
                Text(option.icon)
                    .font(.system(size: 32))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
    
    private func enemyAssetName(_ kind: RuntimeEnemyKind) -> String? {
        switch kind {
        case .punisher: return "punisher"
        case .graphiteGolem: return "graphite_golem"
        case .zesurumiMonks: return "zesurumi_monks"
        case .feyanchа: return "feyancha"
        }
    }
    
    // MARK: - Safety Indicator (for non-combat rooms)
    
    private func safeIndicator(_ kind: RoomKind) -> some View {
        let (icon, label, color): (String, String, Color) = {
            switch kind {
            case .event: return ("sparkles", "Выбор", .blue)
            case .rest: return ("heart.fill", "Отдых", .green)
            case .chest: return ("gift.fill", "Награда", .yellow)
            default: return ("checkmark.shield", "Безопасно", .green)
            }
        }()
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Difficulty Indicator
    
    private func difficultyIndicator(_ level: Int) -> some View {
        HStack(spacing: 4) {
            // Skulls for danger level
            ForEach(0..<level, id: \.self) { _ in
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(difficultyColor(level))
            }
            
            // Text label
            Text(difficultyLabel(level))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(difficultyColor(level))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(difficultyColor(level).opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(difficultyColor(level).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func difficultyLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Бой"
        case 2: return "Опасно"
        case 3: return "Босс"
        default: return ""
        }
    }
    
    private func difficultyColor(_ level: Int) -> Color {
        switch level {
        case 1: return .orange
        case 2: return .red
        case 3: return .purple
        default: return .gray
        }
    }
}

// MARK: - Local helpers

private struct TowerHPBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let f = max(0, min(1, fraction))
            let fillW = CGFloat(f) * w

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 4)
                    .fill(UIStyle.Colors.hpGreen)
                    .frame(width: fillW)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityHidden(true)
    }
}
