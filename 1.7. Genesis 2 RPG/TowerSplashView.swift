import SwiftUI

struct TowerSplashView: View {
    @EnvironmentObject private var store: GameStore
    @State private var didContinue: Bool = false

    var body: some View {
        ZStack {
            Image("tower")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Subtle overlay for legibility
            LinearGradient(
                colors: [
                    .black.opacity(0.55),
                    .black.opacity(0.10),
                    .black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 12)
                    .padding(.horizontal, 18)

                Spacer(minLength: 0)

                footer
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
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
                    .foregroundStyle(.white)

                HStack {
                    Button {
                        store.goToHub()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func metaChip(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.80))
                .frame(maxWidth: .infinity)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        Text("Tap to enter")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.85))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }

    private func proceed() {
        guard !didContinue else { return }
        didContinue = true
        store.goToTower()
    }
}

