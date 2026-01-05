import SwiftUI

struct TowerView: View {
    @EnvironmentObject private var store: GameStore

    // MARK: - Layout constants (UI-KIT v1.0)
    private let contentCap: CGFloat = 380
    private let outerPad: CGFloat = 0

    private let topPad: CGFloat = 10
    private let headerToToast: CGFloat = 10
    private let toastToMeta: CGFloat = 12
    private let metaToRooms: CGFloat = 14
    private let roomsSpacing: CGFloat = 12
    private let bottomPad: CGFloat = 14

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

                ScrollView(.vertical) {
                    VStack(spacing: 0) {

                        // Header
                        headerRow
                            .frame(width: contentWidth, alignment: .center)
                            .padding(.top, topPad)

                        Spacer().frame(height: headerToToast)

                        // Toast
                        toastView
                            .frame(width: contentWidth, alignment: .center)

                        Spacer().frame(height: toastToMeta)

                        // Meta (Floor / Streak)
                        metaRow
                            .frame(width: contentWidth, alignment: .center)

                        Spacer().frame(height: metaToRooms)

                        // Rooms list
                        roomsList
                            .frame(width: contentWidth, alignment: .center)

                        Spacer().frame(height: 16)

                        // Back
                        Button("Back to Hub") {
                            store.goToHub()
                        }
                        .frame(width: contentWidth, alignment: .center)

                        Spacer().frame(height: bottomPad)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
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
        ZStack {
            Text("Tower")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
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
        let floor = store.run?.currentFloor ?? 0
        let streak = store.run?.nonCombatStreak ?? 0

        return HStack(spacing: 12) {
            metaChip(title: "Floor", value: "\(floor)")
            metaChip(title: "Streak", value: "\(streak)")
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }

    private func metaChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(minWidth: 70, alignment: .leading)
    }

    // MARK: - Rooms

    private var roomsList: some View {
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

                Text(option.kind == .combat ? "Combat • Random enemy" : "Chest • Relic")
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
