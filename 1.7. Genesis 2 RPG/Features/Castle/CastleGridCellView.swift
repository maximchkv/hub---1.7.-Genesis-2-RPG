import SwiftUI

struct CastleGridCellView: View {
    let index: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.thinMaterial)
            .overlay(
                Text("Empty")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            )
            .onTapGesture {
                // UI only (no logic)
            }
    }
}
