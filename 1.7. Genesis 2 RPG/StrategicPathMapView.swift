import SwiftUI

struct StrategicPathMapView: View {
    @EnvironmentObject private var store: GameStore
    
    private let previewDepth: Int = 4 // Показываем 4 этажа вперёд
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Путь")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let run = store.run {
                pathMapView(run: run)
            } else {
                Text("Нет активного забега")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
    
    private func pathMapView(run: RunState) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Текущий этаж
                floorNode(
                    floor: run.globalFloor,
                    isCurrent: true,
                    rooms: run.roomOptions
                )
                
                // Будущие этажи
                ForEach(1..<previewDepth, id: \.self) { offset in
                    // Декоративный элемент между этажами
                    pathConnector()
                    
                    // Генерируем превью следующего этажа
                    if let preview = generateFloorPreview(run: run, offset: offset) {
                        floorNode(
                            floor: run.globalFloor + offset,
                            isCurrent: false,
                            rooms: preview
                        )
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func floorNode(floor: Int, isCurrent: Bool, rooms: [RoomOption]) -> some View {
        VStack(spacing: 8) {
            // Номер этажа
            Text("\(floor)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isCurrent ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isCurrent ? Color.accentColor.opacity(0.2) : Color.clear)
                .clipShape(Capsule())
            
            // Иконки комнат
            HStack(spacing: 6) {
                ForEach(rooms.prefix(3)) { room in
                    roomIcon(room: room, isCurrent: isCurrent)
                }
                
                // Если комнат меньше 3, показываем секретную
                if rooms.count < 3 {
                    secretRoomIcon()
                }
            }
            
            // Placeholder для арта (декоративный элемент)
            artPlaceholder(size: 40)
        }
        .frame(width: 80)
        .padding(.vertical, 8)
    }
    
    private func roomIcon(room: RoomOption, isCurrent: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(isCurrent ? 0.15 : 0.08))
                .frame(width: 24, height: 24)
            
            Text(room.icon)
                .font(.system(size: 12))
        }
    }
    
    private func secretRoomIcon() -> some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 24, height: 24)
            
            Image(systemName: "questionmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    private func pathConnector() -> some View {
        HStack(spacing: 4) {
            // Декоративный placeholder для арта между этажами
            artPlaceholder(size: 30)
            
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func artPlaceholder(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.1),
                        Color.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
    }
    
    private func generateFloorPreview(run: RunState, offset: Int) -> [RoomOption]? {
        // Создаём временный run для следующего этажа
        var tempRun = run
        for _ in 0..<offset {
            tempRun.advanceAfterClearingCurrentFloor()
            if tempRun.isCompleted {
                return nil
            }
        }
        
        // Генерируем комнаты для этого этажа
        var towerService = TowerService()
        let allOptions = towerService.generateAllNextFloorOptions(run: tempRun)
        
        // Возвращаем 2 из 3 (третий секретный)
        guard allOptions.count >= 2 else {
            return allOptions
        }
        return Array(allOptions.shuffled().prefix(2))
    }
}
