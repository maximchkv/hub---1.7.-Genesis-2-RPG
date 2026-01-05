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

    // Hero image (Tower)
    private let towerHeroCorner: CGFloat = 16
    private let headerToHero: CGFloat = 10
    private let heroToToast: CGFloat = 10

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

                    Spacer().frame(height: headerToHero)

                    // Hero image block (square 1:1)
                    towerHero(contentWidth: contentWidth)
                        .frame(width: contentWidth, alignment: .center)

                    Spacer().frame(height: heroToToast)

                    // Toast
                    toastView
                        .frame(width: contentWidth, alignment: .center)

                    Spacer().frame(height: toastToMeta)

                    // Meta (Floor / Run streak)
                    metaRow
                        .frame(width: contentWidth, alignment: .center)

                    Spacer().frame(height: metaToRooms)

                    // Center area (roomsList centered vertically)
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        roomsList
                            .frame(width: contentWidth, alignment: .center)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Bottom button pinned to screen bottom
                    Button("Back to Hub") {
                        store.goToHub()
                    }
                    .padding(.bottom, bottomPad)
                    .frame(width: contentWidth, alignment: .center)
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
        Text("Tower")
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func towerHero(contentWidth: CGFloat) -> some View {
        Image("tower")
            .resizable()
            .scaledToFill()
            .frame(width: contentWidth, height: contentWidth) // квадрат
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: towerHeroCorner))
            .overlay(
                RoundedRectangle(cornerRadius: towerHeroCorner)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
            .accessibilityLabel("Tower illustration")
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
                .frame(maxWidth: .infinity)

            metaChip(title: "Run streak", value: "\(streak)")
                .frame(maxWidth: .infinity)
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
