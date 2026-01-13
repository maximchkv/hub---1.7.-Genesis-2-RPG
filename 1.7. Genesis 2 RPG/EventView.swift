import SwiftUI

struct EventView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Event")
                .font(.largeTitle)

            if let event = store.event {
                VStack(spacing: 10) {
                    Text(event.title)
                        .font(.headline)

                    Text(event.text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 12)

                    ForEach(event.options) { opt in
                        Button(opt.title) {
                            store.chooseEventOption(opt)
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                Text("No event state (stub)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Back to Tower") {
                    store.goToTower()
                }
            }
        }
        .padding()
    }
}

