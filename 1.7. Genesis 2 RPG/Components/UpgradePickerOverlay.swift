import SwiftUI

struct UpgradePickerOverlay: View {
    let title: String
    let icon: String
    let currentLevel: Int
    let incomePerDay: Int

    let onUpgrade: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 12) {
                Text("Upgrade")
                    .font(.headline)

                HStack(spacing: 10) {
                    Text(icon)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                        Text("Lv \(currentLevel)  →  Lv \(currentLevel + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("+\(incomePerDay)/day (current)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    onUpgrade()
                } label: {
                    Text("Upgrade +1")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button("Cancel") {
                    onCancel()
                }
                .padding(.top, 2)
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
