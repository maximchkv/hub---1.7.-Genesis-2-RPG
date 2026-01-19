import SwiftUI

// MARK: - Map Legend View

/// A compact legend showing what each room icon means
/// Fixed overlay on the map view
struct MapLegendView: View {
    @State private var isExpanded = false
    
    private let legendItems: [(icon: String, label: String)] = [
        ("⚔️", "Бой"),
        ("💀", "Элита"),
        ("👑", "Босс"),
        ("🧰", "Сундук"),
        ("🔥", "Отдых"),
        ("❓", "Событие")
    ]
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .medium))
                    if !isExpanded {
                        Text("Легенда")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.thinMaterial)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            // Expanded legend
            if isExpanded {
                legendContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
            }
        }
    }
    
    private var legendContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(legendItems, id: \.icon) { item in
                HStack(spacing: 8) {
                    Text(item.icon)
                        .font(.system(size: 14))
                        .frame(width: 20)
                    
                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Compact Inline Legend

/// A single-line legend for tight spaces
struct MapLegendInlineView: View {
    private let mainItems: [(icon: String, label: String)] = [
        ("⚔️", "Бой"),
        ("💀", "Элита"),
        ("🧰", "Сундук"),
        ("🔥", "Отдых")
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(mainItems, id: \.icon) { item in
                HStack(spacing: 4) {
                    Text(item.icon)
                        .font(.system(size: 12))
                    Text(item.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Expandable Legend") {
    VStack {
        Spacer()
        HStack {
            Spacer()
            MapLegendView()
        }
        .padding()
    }
    .frame(width: 300, height: 400)
    .background(Color.gray.opacity(0.1))
}

#Preview("Inline Legend") {
    MapLegendInlineView()
        .padding()
}
