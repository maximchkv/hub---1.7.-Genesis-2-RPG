import SwiftUI

struct TowerView: View {
    @EnvironmentObject private var store: GameStore

    // MARK: - Layout constants (UI-KIT v1.0)
    private let contentCap: CGFloat = 380
    private let outerPad: CGFloat = 0

    private let topPad: CGFloat = 10
    private let toastToMeta: CGFloat = 12
    private let metaToRooms: CGFloat = 14
    private let roomsSpacing: CGFloat = 12

    // Card styling
    private let cardCorner: CGFloat = 16
    private let cardHPad: CGFloat = 14
    private let cardVPad: CGFloat = 16

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

                    // Meta (Floor / Run streak)
                    metaRow
                        .frame(width: contentWidth, alignment: .center)

                    Spacer().frame(height: metaToRooms)

                    roomsList
                        .frame(width: contentWidth, alignment: .center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

            Text("Tower")
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

    private var metaRow: some View {
        let act = store.run?.actIndex ?? 0
        let floorInAct = store.run?.floorInAct ?? 0
        let bossIn = store.run?.floorsRemainingToBoss ?? 0
        let hp = store.run?.playerHP ?? 0
        let maxHP = store.run?.playerMaxHP ?? 0
        let streak = store.run?.nonCombatStreak ?? 0

        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                metaChip(title: "Act", value: "\(act)/\(RunState.actCount)")
                    .frame(maxWidth: .infinity)

                metaChip(title: "Floor", value: "\(floorInAct)/\(RunState.floorsPerAct + 1)")
                    .frame(maxWidth: .infinity)

                metaChip(title: "Boss in", value: "\(bossIn)")
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                metaChip(title: "HP", value: "\(hp)/\(maxHP)")
                    .frame(maxWidth: .infinity)
                metaChip(title: "Streak", value: "\(streak)")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .accessibilityLabel("Act \(act), floor \(floorInAct). Boss in \(bossIn). HP \(hp) of \(maxHP). Streak \(streak).")
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

    // MARK: - Rooms

    private var roomsList: some View {
        ScrollView(.vertical) {
            VStack(spacing: roomsSpacing) {
                ForEach(store.run?.roomOptions ?? []) { option in
                    Button {
                        store.selectRoom(option)
                    } label: {
                        roomCard(option)
                    }
                    .buttonStyle(.plain)
                    .disabled(option.isLocked)
                    .opacity(option.isLocked ? 0.55 : 1.0)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func roomCard(_ option: RoomOption) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.06))

                Text(option.icon)
                    .font(.title2)
            }
            .frame(width: 44, height: 44)

            // Texts
            VStack(alignment: .leading, spacing: 6) {
                Text(option.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(option.kindDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !option.subtitle.isEmpty {
                    Text(option.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            // Trailing affordance
            if option.isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, cardHPad)
        .padding(.vertical, cardVPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
}
