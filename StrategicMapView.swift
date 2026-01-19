import SwiftUI

// MARK: - Map Node Button Style

/// Custom button style for map nodes with press feedback
struct MapNodeButtonStyle: ButtonStyle {
    let state: MapNodeState
    let nodeSize: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && state == .reachable ? 0.88 : 1.0)
            .opacity(configuration.isPressed && state == .reachable ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Strategic Map View

/// Displays the tower map with branching paths in a vertical scrollable view
/// Player position is at the bottom, boss at the top (Slay the Spire style)
struct StrategicMapView: View {
    @EnvironmentObject private var store: GameStore
    
    // Layout constants
    private let nodeSize: CGFloat = 32
    private let floorSpacing: CGFloat = 100  // Фиксированное расстояние между уровнями
    private let edgeLineWidth: CGFloat = 2
    private let horizontalPadding: CGFloat = 12
    
    var body: some View {
        GeometryReader { geo in
            if let map = store.run?.towerMap {
                mapContent(map: map, containerSize: geo.size)
            } else {
                emptyMapPlaceholder
            }
        }
    }
    
    // MARK: - Map Content
    
    private func mapContent(map: TowerMap, containerSize: CGSize) -> some View {
        let totalFloors = map.totalFloors
        let usableWidth = containerSize.width - horizontalPadding * 2
        
        // Фиксированная высота контента — карта скроллится
        let contentHeight = CGFloat(totalFloors - 1) * floorSpacing + nodeSize + UIStyle.Spacing.xl * 2
        
        return ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Draw all edges first (below nodes)
                    edgesCanvas(
                        map: map,
                        usableWidth: usableWidth,
                        contentHeight: contentHeight,
                        totalFloors: totalFloors
                    )
                    
                    // Draw all nodes on top
                    nodesOverlay(
                        map: map,
                        usableWidth: usableWidth,
                        totalFloors: totalFloors
                    )
                }
                .frame(width: containerSize.width, height: contentHeight)
            }
            .onAppear {
                // Скролл к нижней части (floor 1) при появлении
                scrollToBottom(scrollProxy: scrollProxy)
            }
        }
    }
    
    // MARK: - Coordinate Helpers
    
    /// Calculate Y position for a floor (floor 1 at bottom, boss at top)
    private func yPositionForFloor(_ floor: Int, totalFloors: Int) -> CGFloat {
        // Floor 1 внизу, boss (totalFloors) вверху
        let invertedFloor = totalFloors - floor
        return UIStyle.Spacing.xl + CGFloat(invertedFloor) * floorSpacing + nodeSize / 2
    }
    
    /// Calculate X position for a node dynamically based on nodes count on floor
    private func xPositionForNode(_ node: MapNode, nodesOnFloor: [MapNode], usableWidth: CGFloat) -> CGFloat {
        let count = nodesOnFloor.count
        
        // Небольшой отступ от краёв чтобы узлы не вылезали
        let edgeInset: CGFloat = nodeSize / 2 + 4
        let effectiveWidth = usableWidth - edgeInset * 2
        
        guard count > 1 else {
            // Один узел — по центру
            return horizontalPadding + usableWidth / 2
        }
        
        // Найти индекс узла на этом уровне (сортировка по xPosition для сохранения порядка)
        let sorted = nodesOnFloor.sorted { $0.xPosition < $1.xPosition }
        guard let index = sorted.firstIndex(where: { $0.id == node.id }) else {
            return horizontalPadding + usableWidth / 2
        }
        
        // Равномерное распределение с учётом отступов от краёв
        let spacing = effectiveWidth / CGFloat(count - 1)
        return horizontalPadding + edgeInset + CGFloat(index) * spacing
    }
    
    // MARK: - Edges Canvas
    
    private func edgesCanvas(
        map: TowerMap,
        usableWidth: CGFloat,
        contentHeight: CGFloat,
        totalFloors: Int
    ) -> some View {
        Canvas { context, size in
            for floor in 1..<totalFloors {
                let currentNodes = map.nodes(onFloor: floor)
                let nextNodes = map.nodes(onFloor: floor + 1)
                
                for node in currentNodes {
                    let startX = xPositionForNode(node, nodesOnFloor: currentNodes, usableWidth: usableWidth)
                    let startY = yPositionForFloor(floor, totalFloors: totalFloors)
                    
                    for targetId in node.edges {
                        guard let targetNode = nextNodes.first(where: { $0.id == targetId }) else { continue }
                        
                        let endX = xPositionForNode(targetNode, nodesOnFloor: nextNodes, usableWidth: usableWidth)
                        let endY = yPositionForFloor(floor + 1, totalFloors: totalFloors)
                        
                        // Edge attachment points on circle boundaries
                        let startPoint = edgeAttachmentPoint(
                            from: CGPoint(x: startX, y: startY),
                            to: CGPoint(x: endX, y: endY),
                            nodeRadius: nodeSize / 2
                        )
                        let endPoint = edgeAttachmentPoint(
                            from: CGPoint(x: endX, y: endY),
                            to: CGPoint(x: startX, y: startY),
                            nodeRadius: nodeSize / 2
                        )
                        
                        var path = Path()
                        path.move(to: startPoint)
                        
                        // Curved path
                        let midY = (startPoint.y + endPoint.y) / 2
                        let controlOffset = abs(endX - startX) * 0.25
                        path.addCurve(
                            to: endPoint,
                            control1: CGPoint(x: startPoint.x, y: midY + controlOffset),
                            control2: CGPoint(x: endPoint.x, y: midY - controlOffset)
                        )
                        
                        let edgeColor = self.edgeColor(from: node, to: targetNode, map: map)
                        context.stroke(path, with: .color(edgeColor), lineWidth: edgeLineWidth)
                    }
                }
            }
        }
        .frame(width: usableWidth + horizontalPadding * 2, height: contentHeight)
    }
    
    private func edgeAttachmentPoint(from center: CGPoint, to target: CGPoint, nodeRadius: CGFloat) -> CGPoint {
        let dx = target.x - center.x
        let dy = target.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else { return center }
        
        let nx = dx / distance * nodeRadius
        let ny = dy / distance * nodeRadius
        
        return CGPoint(x: center.x + nx, y: center.y + ny)
    }
    
    // MARK: - Nodes Overlay
    
    private func nodesOverlay(
        map: TowerMap,
        usableWidth: CGFloat,
        totalFloors: Int
    ) -> some View {
        ForEach(1...totalFloors, id: \.self) { floor in
            let nodes = map.nodes(onFloor: floor)
            let y = yPositionForFloor(floor, totalFloors: totalFloors)
            
            ForEach(nodes) { node in
                let x = xPositionForNode(node, nodesOnFloor: nodes, usableWidth: usableWidth)
                
                nodeView(node: node, map: map)
                    .position(x: x, y: y)
                    .id(floor == 1 ? "floor_1" : nil) // Для скролла к началу
            }
        }
    }
    
    // MARK: - Node View
    
    private func nodeView(node: MapNode, map: TowerMap) -> some View {
        let state = map.nodeState(for: node.id)
        let isInteractive = state == .reachable
        
        return Button {
            if isInteractive {
                store.selectRoom(node.room)
            }
        } label: {
            nodeContent(node: node, state: state)
        }
        .buttonStyle(MapNodeButtonStyle(state: state, nodeSize: nodeSize))
        .disabled(!isInteractive)
        .accessibilityLabel("\(node.room.title), \(stateAccessibilityLabel(state))")
        .accessibilityHint(isInteractive ? "Нажмите для выбора" : "")
    }
    
    private func nodeContent(node: MapNode, state: MapNodeState) -> some View {
        ZStack {
            // Background circle
            Circle()
                .fill(nodeBackgroundColor(state: state))
                .frame(width: nodeSize, height: nodeSize)
            
            // Border
            Circle()
                .stroke(nodeBorderColor(state: state), lineWidth: nodeBorderWidth(state: state))
                .frame(width: nodeSize, height: nodeSize)
            
            // Icon
            Text(node.room.icon)
                .font(.system(size: nodeSize * 0.5))
                .opacity(nodeIconOpacity(state: state))
        }
        .shadow(
            color: nodeShadowColor(state: state),
            radius: state == .reachable ? 6 : (state == .current ? 4 : 0),
            x: 0,
            y: state == .reachable ? 2 : 0
        )
    }
    
    // MARK: - Scroll Helper
    
    private func scrollToBottom(scrollProxy: ScrollViewProxy) {
        // Скролл к нижней части карты (floor 1) при появлении
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                scrollProxy.scrollTo("floor_1", anchor: .bottom)
            }
        }
    }
    
    // MARK: - Edge Color
    
    private func edgeColor(from source: MapNode, to target: MapNode, map: TowerMap) -> Color {
        let sourceState = map.nodeState(for: source.id)
        let targetState = map.nodeState(for: target.id)
        
        // Visited path
        if sourceState == .visited && targetState == .visited {
            return Color.primary.opacity(0.35)
        }
        
        // Current to reachable
        if sourceState == .current && targetState == .reachable {
            return UIStyle.Colors.accent
        }
        
        // Reachable from floor 1 (no current node yet)
        if sourceState == .reachable && targetState == .reachable {
            return UIStyle.Colors.accent.opacity(0.6)
        }
        
        // Reachable source
        if sourceState == .reachable {
            return Color.primary.opacity(0.35)
        }
        
        // Default unreachable
        return Color.primary.opacity(0.12)
    }
    
    // MARK: - Node Styling
    
    private func nodeBackgroundColor(state: MapNodeState) -> Color {
        switch state {
        case .current:
            return UIStyle.Colors.accent.opacity(0.15)
        case .visited:
            return Color.primary.opacity(0.06)
        case .reachable:
            return Color.white
        case .unreachable:
            return Color.primary.opacity(0.04)
        }
    }
    
    private func nodeBorderColor(state: MapNodeState) -> Color {
        switch state {
        case .current:
            return UIStyle.Colors.accent
        case .visited:
            return Color.primary.opacity(0.25)
        case .reachable:
            return UIStyle.Colors.accent
        case .unreachable:
            return Color.primary.opacity(0.12)
        }
    }
    
    private func nodeBorderWidth(state: MapNodeState) -> CGFloat {
        switch state {
        case .current: return 3
        case .reachable: return 2.5
        case .visited: return 1.5
        case .unreachable: return 1
        }
    }
    
    private func nodeIconOpacity(state: MapNodeState) -> Double {
        switch state {
        case .current: return 1.0
        case .visited: return 0.35
        case .reachable: return 1.0
        case .unreachable: return 0.25
        }
    }
    
    private func nodeShadowColor(state: MapNodeState) -> Color {
        switch state {
        case .current:
            return UIStyle.Colors.accent.opacity(0.3)
        case .reachable:
            return Color.black.opacity(0.15)
        case .visited, .unreachable:
            return Color.clear
        }
    }
    
    private func stateAccessibilityLabel(_ state: MapNodeState) -> String {
        switch state {
        case .current: return "текущая позиция"
        case .visited: return "посещено"
        case .reachable: return "доступно"
        case .unreachable: return "недоступно"
        }
    }
    
    // MARK: - Empty State
    
    private var emptyMapPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Карта недоступна")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var store = GameStore()
        
        var body: some View {
            StrategicMapView()
                .environmentObject(store)
                .frame(height: 500)
                .background(.thinMaterial)
                .onAppear {
                    store.startRun(routeToHub: false)
                }
        }
    }
    
    return PreviewWrapper()
}
