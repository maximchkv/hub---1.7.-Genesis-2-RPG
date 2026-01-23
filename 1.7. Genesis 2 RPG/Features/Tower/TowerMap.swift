import Foundation

// MARK: - Map Node

/// A single node on the tower map representing a room choice
struct MapNode: Identifiable, Codable, Hashable {
    let id: UUID
    let floor: Int // 1-based floor within the act (1...11 for 10 floors + boss)
    let room: RoomOption
    
    /// IDs of nodes on the next floor that this node connects to
    var edges: Set<UUID>
    
    /// Horizontal position for layout (0.0 = left, 1.0 = right)
    let xPosition: CGFloat
    
    init(
        id: UUID = UUID(),
        floor: Int,
        room: RoomOption,
        edges: Set<UUID> = [],
        xPosition: CGFloat = 0.5
    ) {
        self.id = id
        self.floor = floor
        self.room = room
        self.edges = edges
        self.xPosition = xPosition
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MapNode, rhs: MapNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tower Map

/// Represents the full map for one act with branching paths
struct TowerMap: Codable {
    /// All nodes organized by floor (floor -> [nodes])
    private(set) var nodesByFloor: [Int: [MapNode]]
    
    /// Quick lookup by node ID
    private var nodesById: [UUID: MapNode]
    
    /// The node the player is currently at (nil if not yet entered the map)
    var currentNodeId: UUID?
    
    /// Set of nodes the player has already visited/completed
    var visitedNodeIds: Set<UUID>
    
    /// The act this map belongs to (1, 2, or 3)
    let actIndex: Int
    
    /// Total floors in this act (including boss)
    let totalFloors: Int
    
    init(actIndex: Int, totalFloors: Int = 11) {
        self.actIndex = actIndex
        self.totalFloors = totalFloors
        self.nodesByFloor = [:]
        self.nodesById = [:]
        self.currentNodeId = nil
        self.visitedNodeIds = []
    }
    
    // MARK: - Node Access
    
    /// Get all nodes on a specific floor
    func nodes(onFloor floor: Int) -> [MapNode] {
        nodesByFloor[floor] ?? []
    }
    
    /// Get a specific node by ID
    func node(withId id: UUID) -> MapNode? {
        nodesById[id]
    }
    
    /// Get the current node
    var currentNode: MapNode? {
        guard let id = currentNodeId else { return nil }
        return node(withId: id)
    }
    
    /// Get all nodes in the map
    var allNodes: [MapNode] {
        nodesByFloor.values.flatMap { $0 }
    }
    
    // MARK: - Navigation
    
    /// Get nodes that are reachable from the current position
    /// If no current node, returns all nodes on floor 1
    func reachableNodes() -> [MapNode] {
        guard let currentId = currentNodeId,
              let current = node(withId: currentId) else {
            // Not started yet - all floor 1 nodes are reachable
            return nodes(onFloor: 1)
        }
        
        // Return nodes that current node connects to
        return current.edges.compactMap { node(withId: $0) }
    }
    
    /// Check if a specific node is reachable from current position
    func isReachable(nodeId: UUID) -> Bool {
        guard let currentId = currentNodeId,
              let current = node(withId: currentId) else {
            // Not started yet - floor 1 nodes are reachable
            if let targetNode = node(withId: nodeId) {
                return targetNode.floor == 1
            }
            return false
        }
        
        return current.edges.contains(nodeId)
    }
    
    /// Check if a node has been visited
    func isVisited(nodeId: UUID) -> Bool {
        visitedNodeIds.contains(nodeId)
    }
    
    /// Check if a node is the current node
    func isCurrent(nodeId: UUID) -> Bool {
        currentNodeId == nodeId
    }
    
    // MARK: - State Updates
    
    /// Move to a new node (must be reachable)
    mutating func moveTo(nodeId: UUID) -> Bool {
        guard isReachable(nodeId: nodeId) else { return false }
        
        // Mark current as visited before moving
        if let current = currentNodeId {
            visitedNodeIds.insert(current)
        }
        
        currentNodeId = nodeId
        return true
    }
    
    /// Mark the current node as completed and clear current
    /// Called after completing a room
    mutating func completeCurrentNode() {
        guard let current = currentNodeId else { return }
        visitedNodeIds.insert(current)
    }
    
    // MARK: - Map Building (used by generator)
    
    /// Add a node to the map
    mutating func addNode(_ node: MapNode) {
        if nodesByFloor[node.floor] == nil {
            nodesByFloor[node.floor] = []
        }
        nodesByFloor[node.floor]?.append(node)
        nodesById[node.id] = node
    }
    
    /// Add an edge between two nodes
    mutating func addEdge(from sourceId: UUID, to targetId: UUID) {
        guard var sourceNode = nodesById[sourceId] else { return }
        sourceNode.edges.insert(targetId)
        nodesById[sourceId] = sourceNode
        
        // Update in floor array too
        if let floorNodes = nodesByFloor[sourceNode.floor],
           let index = floorNodes.firstIndex(where: { $0.id == sourceId }) {
            nodesByFloor[sourceNode.floor]?[index] = sourceNode
        }
    }
    
    // MARK: - Validation
    
    /// Verify all nodes are reachable from floor 1 to boss
    func isValid() -> Bool {
        guard let bossNodes = nodesByFloor[totalFloors], !bossNodes.isEmpty else {
            return false
        }
        
        let bossId = bossNodes[0].id
        let startNodes = nodes(onFloor: 1)
        
        // BFS from all start nodes to verify boss is reachable
        var visited = Set<UUID>()
        var queue = startNodes.map { $0.id }
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if visited.contains(current) { continue }
            visited.insert(current)
            
            if current == bossId {
                return true
            }
            
            if let node = node(withId: current) {
                queue.append(contentsOf: node.edges)
            }
        }
        
        return false
    }
    
    // MARK: - Helpers for UI
    
    /// Get the node state for rendering
    func nodeState(for nodeId: UUID) -> MapNodeState {
        if isCurrent(nodeId: nodeId) {
            return .current
        }
        if isVisited(nodeId: nodeId) {
            return .visited
        }
        if isReachable(nodeId: nodeId) {
            return .reachable
        }
        return .unreachable
    }
    
    /// Convert reachable nodes to RoomOptions for backward compatibility
    func reachableRoomOptions() -> [RoomOption] {
        reachableNodes().map { $0.room }
    }
}

// MARK: - Node State

enum MapNodeState {
    case current      // Player is here
    case visited      // Already completed
    case reachable    // Can be selected next
    case unreachable  // Not accessible from current position
}

// MARK: - Codable support for CGFloat in MapNode

extension MapNode {
    enum CodingKeys: String, CodingKey {
        case id, floor, room, edges, xPosition
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        floor = try container.decode(Int.self, forKey: .floor)
        room = try container.decode(RoomOption.self, forKey: .room)
        edges = try container.decode(Set<UUID>.self, forKey: .edges)
        let x = try container.decode(Double.self, forKey: .xPosition)
        xPosition = CGFloat(x)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(floor, forKey: .floor)
        try container.encode(room, forKey: .room)
        try container.encode(edges, forKey: .edges)
        try container.encode(Double(xPosition), forKey: .xPosition)
    }
}
