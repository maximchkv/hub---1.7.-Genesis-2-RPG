import SwiftUI

struct BuildPickerOverlay: View {
    let onSelectMine: () -> Void
    let onSelectFarm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            // dim background + tap outside to dismiss
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 12) {
                Text("Build")
                    .font(.headline)

                VStack(spacing: 10) {
                    Button {
                        onSelectMine()
                    } label: {
                        HStack(spacing: 10) {
                            Text("⛏️")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mine")
                                    .font(.headline)
                                Text("+2/day (stub)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onSelectFarm()
                    } label: {
                        HStack(spacing: 10) {
                            Text("🌾")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Farm")
                                    .font(.headline)
                                Text("+1/day (stub)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button("Cancel") {
                    onCancel()
                }
                .padding(.top, 4)
            }
            .padding(14)
            .frame(maxWidth: 320)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
    }
}
