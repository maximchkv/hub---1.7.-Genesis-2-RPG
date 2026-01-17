import SwiftUI

struct TacticalRoomCardView: View {
    let room: RoomOption
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 0) {
                // Арт-плейсхолдер (левая колонка) - растягивается на всю высоту блока
                artPlaceholderSection
                    .frame(width: 100)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
                        topLeading: 20,
                        bottomLeading: 20,
                        bottomTrailing: 0,
                        topTrailing: 0
                    )))
                
                // Контент карточки (правая колонка)
                VStack(alignment: .leading, spacing: 4) {
                    // Заголовок и индикатор сложности
                    HStack(alignment: .center) {
                        Text(room.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Индикатор сложности/безопасности
                        if room.difficulty > 0 {
                            difficultyIndicator(room.difficulty)
                        } else {
                            safeIndicator(room.kind)
                        }
                    }
                    
                    // Описание типа комнаты
                    Text(room.kindDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    // Текстовое описание (компактно)
                    if !room.descriptionText.isEmpty {
                        Text(room.descriptionText)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    // Превью следующего этажа (компактно)
                    if let preview = room.nextFloorPreview, !preview.isEmpty {
                        nextFloorPreviewSectionCompact(preview)
                    }
                    
                    // Заблокировано сообщение
                    if !room.subtitle.isEmpty {
                        Text(room.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(room.isLocked ? Color.red.opacity(0.3) : Color.primary.opacity(0.12), lineWidth: room.isLocked ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(room.isLocked)
        .opacity(room.isLocked ? 0.6 : 1.0)
    }
    
    // MARK: - Art Placeholder Section
    
    private var artPlaceholderSection: some View {
        ZStack {
            // Фоновый градиент
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.15),
                    Color.primary.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Иконка комнаты или портрет врага
            if let enemy = room.previewEnemy, let assetName = enemyAssetName(enemy) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100)
                    .frame(maxHeight: .infinity)
                    .clipped()
                    .opacity(0.7)
            } else {
                Text(room.icon)
                    .font(.system(size: 24))
            }
            
            // Overlay для глубины
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Next Floor Preview
    
    private func nextFloorPreviewSection(_ preview: [RoomOption]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Следующий этаж:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(preview.prefix(2)) { room in
                    HStack(spacing: 4) {
                        Text(room.icon)
                            .font(.caption)
                        Text(room.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                // Секретная комната
                HStack(spacing: 4) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("?")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Next Floor Preview (Compact)
    
    private func nextFloorPreviewSectionCompact(_ preview: [RoomOption]) -> some View {
        HStack(spacing: 6) {
            Text("→")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            ForEach(preview.prefix(2)) { room in
                Text(room.icon)
                    .font(.caption2)
            }
            
            Text("?")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }
    
    // MARK: - Difficulty Indicator
    
    private func difficultyIndicator(_ level: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<level, id: \.self) { _ in
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(difficultyColor(level))
            }
            
            Text(difficultyLabel(level))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(difficultyColor(level))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(difficultyColor(level).opacity(0.15))
        .clipShape(Capsule())
    }
    
    private func difficultyLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Бой"
        case 2: return "Опасно"
        case 3: return "Босс"
        default: return ""
        }
    }
    
    private func difficultyColor(_ level: Int) -> Color {
        switch level {
        case 1: return .orange
        case 2: return .red
        case 3: return .purple
        default: return .gray
        }
    }
    
    // MARK: - Safety Indicator
    
    private func safeIndicator(_ kind: RoomKind) -> some View {
        let (icon, label, color): (String, String, Color) = {
            switch kind {
            case .event: return ("sparkles", "Выбор", .blue)
            case .rest: return ("heart.fill", "Отдых", .green)
            case .chest: return ("gift.fill", "Награда", .yellow)
            default: return ("checkmark.shield", "Безопасно", .green)
            }
        }()
        
        return HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Enemy Asset Name
    
    private func enemyAssetName(_ kind: RuntimeEnemyKind) -> String? {
        switch kind {
        case .punisher: return "punisher"
        case .graphiteGolem: return "graphite_golem"
        case .zesurumiMonks: return "zesurumi_monks"
        case .feyanchа: return "feyancha"
        }
    }
}
