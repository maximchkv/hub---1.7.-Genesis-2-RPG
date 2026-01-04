import SwiftUI

struct HubView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ZStack {
            UIStyle.background
                .ignoresSafeArea()

            // Existing content (unchanged)
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Days: \(store.meta.days)")
                        Spacer()
                        Text("Gold: \(store.meta.gold)")
                        Spacer()
                        Text("Best: \(store.meta.bestFloor)")
                    }
                    .font(.headline)

                    Text("Current Floor: \(store.run?.currentFloor ?? 0)")
                        .font(.subheadline)

                    Text("Chest streak: \(store.run?.nonCombatStreak ?? 0)")
                        .font(.caption)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

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

                HStack(spacing: 12) {
                    Button("Tower") {
                        store.goToTower()
                    }
                    .disabled(store.run == nil)

                    Button("Castle") { store.goToCastle() }
                    Button("Cards") { store.goToCardLibrary() }
                }

                Button("End Run (debug)") { store.endRun() }
            }
            .padding()
            .onAppear { store.goToHub() }
        }
    }
}
