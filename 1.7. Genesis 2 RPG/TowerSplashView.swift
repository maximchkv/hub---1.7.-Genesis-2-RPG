import SwiftUI

struct TowerSplashView: View {
    @EnvironmentObject private var store: GameStore
    @State private var didContinue: Bool = false

    // Layout tuning
    private let horizontalPad: CGFloat = 18
    private let topPad: CGFloat = 12
    private let artTopGap: CGFloat = 14
    private let artBottomGap: CGFloat = 14
    private let bottomPad: CGFloat = 18

    var body: some View {
        ZStack {
            UIStyle.background()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, topPad)
                    .padding(.horizontal, horizontalPad)

                // Tower art: keep original composition (no crop)
                Image("tower")
                    .resizable()
                    .scaledToFit()
                    .padding(.top, artTopGap)
                    .padding(.bottom, artBottomGap)
                    .padding(.horizontal, horizontalPad)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                footer
                    .padding(.horizontal, horizontalPad)
                    .padding(.bottom, bottomPad)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { proceed() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Text("Tower")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack {
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

                    Spacer(minLength: 0)
                }
            }

            metaCard
                .frame(maxWidth: 360)
        }
    }

    private var metaCard: some View {
        let act = store.run?.actIndex ?? 0
        let floorInAct = store.run?.floorInAct ?? 0
        let floorsTotalInAct = RunState.floorsPerAct + 1
        let bossIn = store.run?.floorsRemainingToBoss ?? 0
        let hp = store.run?.playerHP ?? 0
        let maxHP = store.run?.playerMaxHP ?? 0
        let streak = store.run?.nonCombatStreak ?? 0
        let global = store.run?.globalFloor ?? 0
        let globalTotal = store.run?.globalFloorsTotal ?? 0

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                metaChip(title: "Act", value: "\(act)/\(RunState.actCount)")
                metaChip(title: "Floor", value: "\(floorInAct)/\(floorsTotalInAct)")
                metaChip(title: "Boss in", value: "\(bossIn)")
            }

            HStack(spacing: 10) {
                metaChip(title: "HP", value: "\(hp)/\(maxHP)")
                metaChip(title: "Streak", value: "\(streak)")
                metaChip(title: "Global", value: "\(global)/\(globalTotal)")
            }
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
                .frame(maxWidth: .infinity)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        Text("Tap to enter")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
    }

    private func proceed() {
        guard !didContinue else { return }
        didContinue = true
        store.goToTower()
    }
}

