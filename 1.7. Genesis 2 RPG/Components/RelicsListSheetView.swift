import SwiftUI

struct RelicsListSheetView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if store.meta.artifacts.isEmpty {
                        Text("No relics yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.meta.artifacts.indices, id: \.self) { idx in
                            let art = store.meta.artifacts[idx]
                            HStack(spacing: 10) {
                                Text(art.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(art.name)
                                        .font(.subheadline)
                                    Text(art.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("+\(art.incomeBonus)/day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Relics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
