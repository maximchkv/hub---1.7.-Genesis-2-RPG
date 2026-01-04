import SwiftUI

struct TowerView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Tower")
                .font(.title)

            if let toast = store.toast {
                Text(toast)
                    .font(.caption)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            if store.toast == toast {
                                store.toast = nil
                            }
                        }
                    }
            }

            HStack {
                Text("Floor: \(store.run?.currentFloor ?? 0)")
                Spacer()
                Text("Streak: \(store.run?.nonCombatStreak ?? 0)")
            }
            .font(.headline)

            VStack(spacing: 12) {
                ForEach(store.run?.roomOptions ?? []) { option in
                    Button {
                        store.selectRoom(option)
                    } label: {
                        HStack(spacing: 12) {
                            Text(option.icon)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(option.title)
                                    .font(.headline)

                                Text(option.kind == .combat ? "Combat • Random enemy" : "Chest • Relic")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !option.subtitle.isEmpty {
                                    Text(option.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(option.isLocked ? 0.5 : 1.0)
                    }
                    .disabled(option.isLocked)
                }
            }

            Button("Back to Hub") {
                store.goToHub()
            }
        }
        .padding()
        .onAppear {
            if store.run?.roomOptions.isEmpty ?? true {
                store.refreshRoomOptions()
            }
        }
    }
}
