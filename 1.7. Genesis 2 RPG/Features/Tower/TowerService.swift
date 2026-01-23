import Foundation

struct TowerService {
    
    // MARK: - Room Descriptions
    
    private let combatDescriptions = [
        "Обычные враги охраняют путь.",
        "Впереди слышен звон оружия.",
        "Тени движутся в темноте.",
        "Стражи башни ждут тебя."
    ]
    
    private let eliteDescriptions = [
        "Могущественный противник преграждает путь.",
        "Элитный страж не отступит без боя.",
        "Опасный враг с особыми способностями."
    ]
    
    private let bossDescriptions = [
        "Хозяин этажа ждёт финальной схватки.",
        "Босс акта готов к бою.",
        "Решающее сражение впереди."
    ]
    
    private let eventDescriptions = [
        "Странная встреча ждёт тебя.",
        "Таинственный незнакомец предлагает выбор.",
        "Судьба готовит испытание."
    ]
    
    private let restDescriptions = [
        "Безопасное место для отдыха.",
        "Костёр даёт передышку.",
        "Восстанови силы перед следующим боем."
    ]
    
    private let chestDescriptions = [
        "Древний сундук с сокровищами.",
        "Награда за храбрость.",
        "Артефакт ждёт своего владельца."
    ]
    
    // MARK: - Act Map Generation (Slay the Spire style)
    
    // Grid dimensions
    private let gridColumns = 7  // Number of columns (x positions)
    private let pathCount = 6    // Number of paths to generate
    
    /// Generates a complete branching map for an act using Slay the Spire algorithm
    /// - Parameter actIndex: The act number (1, 2, or 3)
    /// - Returns: A TowerMap with all nodes and edges for the act
    func generateActMap(actIndex: Int) -> TowerMap {
        let floorsPerAct = RunState.floorsPerAct // 10 normal floors
        let totalFloors = floorsPerAct + 1 // +1 for boss
        
        var map = TowerMap(actIndex: actIndex, totalFloors: totalFloors)
        
        // MARK: Step 1 - Create grid of potential nodes
        // Grid: columns 0..<gridColumns, floors 1...totalFloors
        // We'll create nodes only where paths pass through
        
        // Track which grid cells have nodes: [floor][column] -> nodeId
        var gridNodes: [[UUID?]] = Array(
            repeating: Array(repeating: nil, count: gridColumns),
            count: totalFloors + 1 // index 0 unused, floors 1...totalFloors
        )
        
        // Track edges to avoid crossing: Set of (fromCol, toCol) pairs per floor transition
        var edgesPerFloor: [Set<EdgeKey>] = Array(repeating: [], count: totalFloors)
        
        // MARK: Step 2 - Generate paths from bottom to top
        for _ in 0..<pathCount {
            // Pick random starting column
            var currentCol = Int.random(in: 0..<gridColumns)
            
            for floor in 1..<totalFloors {
                // Ensure node exists at current position
                if gridNodes[floor][currentCol] == nil {
                    let room = generateRoomForPosition(floor: floor, column: currentCol, actIndex: actIndex, totalFloors: totalFloors)
                    let xPos = columnToXPosition(currentCol)
                    let node = MapNode(floor: floor, room: room, xPosition: xPos)
                    map.addNode(node)
                    gridNodes[floor][currentCol] = node.id
                }
                
                // Find valid next columns (within ±1, no crossing edges)
                let nextFloor = floor + 1
                var validNextCols: [Int] = []
                
                for nextCol in max(0, currentCol - 1)...min(gridColumns - 1, currentCol + 1) {
                    let edgeKey = EdgeKey(fromCol: currentCol, toCol: nextCol)
                    
                    // Check if this edge would cross existing edges
                    if !wouldCrossExistingEdge(edgeKey, existingEdges: edgesPerFloor[floor]) {
                        validNextCols.append(nextCol)
                    }
                }
                
                // If no valid columns, allow same column
                if validNextCols.isEmpty {
                    validNextCols = [currentCol]
                }
                
                // Pick random valid next column
                let nextCol = validNextCols.randomElement() ?? currentCol
                
                // Ensure node exists at next position (unless it's boss floor)
                if nextFloor < totalFloors {
                    if gridNodes[nextFloor][nextCol] == nil {
                        let room = generateRoomForPosition(floor: nextFloor, column: nextCol, actIndex: actIndex, totalFloors: totalFloors)
                        let xPos = columnToXPosition(nextCol)
                        let node = MapNode(floor: nextFloor, room: room, xPosition: xPos)
                        map.addNode(node)
                        gridNodes[nextFloor][nextCol] = node.id
                    }
                }
                
                // Add edge
                if let fromId = gridNodes[floor][currentCol] {
                    if nextFloor == totalFloors {
                        // Connect to boss (will be created later)
                    } else if let toId = gridNodes[nextFloor][nextCol] {
                        map.addEdge(from: fromId, to: toId)
                        edgesPerFloor[floor].insert(EdgeKey(fromCol: currentCol, toCol: nextCol))
                    }
                }
                
                currentCol = nextCol
            }
        }
        
        // MARK: Step 3 - Add boss node and connect all top-floor nodes to it
        let bossRoom = makeBossRoom(actIndex: actIndex)
        let bossNode = MapNode(floor: totalFloors, room: bossRoom, xPosition: 0.5)
        map.addNode(bossNode)
        
        // Connect all nodes on floor before boss to boss
        let preBossFloor = totalFloors - 1
        for col in 0..<gridColumns {
            if let nodeId = gridNodes[preBossFloor][col] {
                map.addEdge(from: nodeId, to: bossNode.id)
            }
        }
        
        // MARK: Step 4 - Ensure minimum starting options
        // Make sure we have at least 2-3 nodes on floor 1
        let floor1Nodes = map.nodes(onFloor: 1)
        if floor1Nodes.count < 2 {
            // Add more starting nodes
            for col in 0..<gridColumns where gridNodes[1][col] == nil {
                let room = makeCombatRoom()
                let xPos = columnToXPosition(col)
                let node = MapNode(floor: 1, room: room, xPosition: xPos)
                map.addNode(node)
                gridNodes[1][col] = node.id
                
                // Connect to a random node on floor 2
                let floor2Nodes = map.nodes(onFloor: 2)
                if let randomTarget = floor2Nodes.randomElement() {
                    map.addEdge(from: node.id, to: randomTarget.id)
                }
                
                if map.nodes(onFloor: 1).count >= 3 { break }
            }
        }
        
        // Validate the map
        if !map.isValid() {
            // Fallback: regenerate with simpler algorithm
            return generateSimpleActMap(actIndex: actIndex)
        }
        
        return map
    }
    
    /// Convert grid column to x position (0.0 to 1.0)
    private func columnToXPosition(_ column: Int) -> CGFloat {
        let padding: CGFloat = 0.08
        let usableRange = 1.0 - (padding * 2)
        return padding + (CGFloat(column) / CGFloat(gridColumns - 1)) * usableRange
    }
    
    /// Check if a new edge would cross any existing edge
    private func wouldCrossExistingEdge(_ newEdge: EdgeKey, existingEdges: Set<EdgeKey>) -> Bool {
        for existing in existingEdges {
            // Edges cross if one goes left while other goes right
            // (fromCol1 < fromCol2 && toCol1 > toCol2) || (fromCol1 > fromCol2 && toCol1 < toCol2)
            let goesLeft1 = newEdge.toCol < newEdge.fromCol
            let goesRight1 = newEdge.toCol > newEdge.fromCol
            let goesLeft2 = existing.toCol < existing.fromCol
            let goesRight2 = existing.toCol > existing.fromCol
            
            // Check for actual crossing (not just both going same direction)
            if newEdge.fromCol != existing.fromCol && newEdge.toCol != existing.toCol {
                if (newEdge.fromCol < existing.fromCol && newEdge.toCol > existing.toCol) ||
                   (newEdge.fromCol > existing.fromCol && newEdge.toCol < existing.toCol) {
                    return true
                }
            }
        }
        return false
    }
    
    /// Generate room type based on position in the map
    private func generateRoomForPosition(floor: Int, column: Int, actIndex: Int, totalFloors: Int) -> RoomOption {
        let preBossFloor = totalFloors - 1
        
        // Floor 1: Always combat
        if floor == 1 {
            return makeCombatRoom()
        }
        
        // Pre-boss floor: Rest sites
        if floor == preBossFloor {
            return makeRestRoom()
        }
        
        // Mid-floor treasure (around floor 5-6)
        if floor == 5 || floor == 6 {
            if Int.random(in: 0..<10) < 2 { // 20% chance
                return makeChestRoom(isLocked: false)
            }
        }
        
        // Elite encounters (floors 6+, ~10% chance)
        if floor >= 6 && Int.random(in: 0..<10) < 1 {
            return makeEliteRoom()
        }
        
        // Events (floors 2-4, ~25% chance; floors 5+, ~15% chance)
        let eventChance = floor <= 4 ? 25 : 15
        if Int.random(in: 0..<100) < eventChance {
            return makeEventRoom()
        }
        
        // Rest (floors 4+, ~10% chance, but not on pre-boss)
        if floor >= 4 && floor < preBossFloor && Int.random(in: 0..<10) < 1 {
            return makeRestRoom()
        }
        
        // Default: Combat
        return makeCombatRoom()
    }
    
    /// Fallback simple map generator
    private func generateSimpleActMap(actIndex: Int) -> TowerMap {
        let totalFloors = RunState.floorsPerAct + 1
        var map = TowerMap(actIndex: actIndex, totalFloors: totalFloors)
        
        // Create 2-3 nodes per floor in a simple pattern
        var previousNodes: [MapNode] = []
        
        for floor in 1...totalFloors {
            var currentNodes: [MapNode] = []
            
            if floor == totalFloors {
                // Boss floor
                let bossNode = MapNode(floor: floor, room: makeBossRoom(actIndex: actIndex), xPosition: 0.5)
                map.addNode(bossNode)
                currentNodes = [bossNode]
            } else {
                // Regular floor: 2-3 nodes
                let count = floor == 1 ? 3 : Int.random(in: 2...3)
                for i in 0..<count {
                    let xPos = CGFloat(i) / CGFloat(max(1, count - 1)) * 0.7 + 0.15
                    let room = floor == 1 ? makeCombatRoom() : generateRoomForPosition(floor: floor, column: i, actIndex: actIndex, totalFloors: totalFloors)
                    let node = MapNode(floor: floor, room: room, xPosition: xPos)
                    map.addNode(node)
                    currentNodes.append(node)
                }
            }
            
            // Connect to previous floor
            if !previousNodes.isEmpty {
                for prevNode in previousNodes {
                    // Connect to 1-2 nodes on current floor
                    let connectCount = min(currentNodes.count, Int.random(in: 1...2))
                    let sorted = currentNodes.sorted { abs($0.xPosition - prevNode.xPosition) < abs($1.xPosition - prevNode.xPosition) }
                    for i in 0..<connectCount {
                        map.addEdge(from: prevNode.id, to: sorted[i].id)
                    }
                }
            }
            
            previousNodes = currentNodes
        }
        
        return map
    }
    
    /// Helper struct for tracking edges
    private struct EdgeKey: Hashable {
        let fromCol: Int
        let toCol: Int
    }
    
    /// Generates room types for a floor following game rules (legacy, kept for compatibility)
    private func generateRoomsForFloor(floor: Int, count: Int, actIndex: Int) -> [RoomOption] {
        let floorsPerAct = RunState.floorsPerAct
        let isPreBossFloor = floor == floorsPerAct
        
        var rooms: [RoomOption] = []
        
        // Pre-boss floor: guarantee Rest among options
        if isPreBossFloor {
            rooms.append(makeRestRoom())
            for _ in 1..<count {
                rooms.append(makeCombatRoom())
            }
            return rooms.shuffled()
        }
        
        // Floor 1: Start with combat/event mix
        if floor == 1 {
            rooms.append(makeCombatRoom())
            rooms.append(makeCombatRoom())
            if count > 2 {
                rooms.append(makeEventRoom())
            }
            return rooms.shuffled()
        }
        
        // Regular floor logic
        for i in 0..<count {
            let room: RoomOption
            
            if i == 0 {
                // First slot: always combat
                room = makeCombatRoom()
            } else if i == 1 {
                // Second slot: combat or elite (elite on mid/late floors)
                if floor >= 5 && floor % 2 == 1 {
                    room = makeEliteRoom()
                } else {
                    room = makeCombatRoom()
                }
            } else {
                // Third slot: special (event or chest)
                if floor <= 2 {
                    room = makeEventRoom()
                } else {
                    let choices: [RoomKind] = [.event, .chest, .chest, .rest]
                    let picked = choices.randomElement() ?? .event
                    switch picked {
                    case .chest: room = makeChestRoom(isLocked: false)
                    case .rest: room = makeRestRoom()
                    default: room = makeEventRoom()
                    }
                }
            }
            
            rooms.append(room)
        }
        
        return rooms.shuffled()
    }
    
    // MARK: - Legacy Generation (backward compat)
    
    func generateRoomOptions(run: RunState) -> [RoomOption] {
        // Generate next floor preview first
        let nextFloorPreview = generateNextFloorPreview(run: run)
        
        // Boss floor: single mandatory option
        if run.isBossFloor {
            var bossRoom = makeBossRoom(actIndex: run.actIndex)
            bossRoom.nextFloorPreview = nextFloorPreview
            return [bossRoom]
        }

        // Pre-boss floor: guarantee Rest among the 3 options
        if run.floorInAct == RunState.floorsPerAct {
            var options: [RoomOption] = [
                makeCombatRoom(),
                makeCombatRoom(),
                makeRestRoom()
            ]
            // Attach preview to each option
            for i in 0..<options.count {
                options[i].nextFloorPreview = nextFloorPreview
            }
            options.shuffle()
            return options
        }

        // Base: two combats + one "special"
        var optionA = makeCombatRoom()
        var optionB = makeCombatRoom()

        // Sprinkle elites in mid/late act by upgrading one combat slot.
        if run.floorInAct >= 5, run.floorInAct % 2 == 1 {
            optionB = makeEliteRoom()
        }

        // Special slot: event early, event/chest later (chest can be locked)
        let chestLocked = (run.nonCombatStreak >= 2)
        let special: RoomOption = {
            if run.floorInAct <= 2 {
                return makeEventRoom()
            }
            let pool: [RoomKind] = [.event, .chest, .chest]
            let picked = pool.randomElement() ?? .event
            if picked == .chest {
                return makeChestRoom(isLocked: chestLocked)
            }
            return makeEventRoom()
        }()

        var options: [RoomOption] = [optionA, optionB, special]
        // Attach preview to each option
        for i in 0..<options.count {
            options[i].nextFloorPreview = nextFloorPreview
        }
        options.shuffle()
        return options
    }
    
    // MARK: - Next Floor Preview Generation
    
    private func generateNextFloorPreview(run: RunState) -> [RoomOption]? {
        // If this is the last floor of the last act, no next floor
        if run.isBossFloor && run.actIndex >= RunState.actCount {
            return nil
        }
        
        // Create a temporary run state for the next floor
        var nextRun = run
        nextRun.advanceAfterClearingCurrentFloor()
        
        // If next floor is completed, no preview
        if nextRun.isCompleted {
            return nil
        }
        
        // Generate all 3 options for next floor
        let allNextOptions = generateAllNextFloorOptions(run: nextRun)
        
        // Return 2 random options (third is secret)
        guard allNextOptions.count >= 2 else {
            return allNextOptions
        }
        
        let shuffled = allNextOptions.shuffled()
        return Array(shuffled.prefix(2))
    }
    
    func generateAllNextFloorOptions(run: RunState) -> [RoomOption] {
        // Boss floor: single mandatory option
        if run.isBossFloor {
            return [makeBossRoom(actIndex: run.actIndex)]
        }

        // Pre-boss floor: guarantee Rest among the 3 options
        if run.floorInAct == RunState.floorsPerAct {
            return [
                makeCombatRoom(),
                makeCombatRoom(),
                makeRestRoom()
            ]
        }

        // Base: two combats + one "special"
        var optionA = makeCombatRoom()
        var optionB = makeCombatRoom()

        // Sprinkle elites in mid/late act by upgrading one combat slot.
        if run.floorInAct >= 5, run.floorInAct % 2 == 1 {
            optionB = makeEliteRoom()
        }

        // Special slot: event early, event/chest later (chest can be locked)
        let chestLocked = (run.nonCombatStreak >= 2)
        let special: RoomOption = {
            if run.floorInAct <= 2 {
                return makeEventRoom()
            }
            let pool: [RoomKind] = [.event, .chest, .chest]
            let picked = pool.randomElement() ?? .event
            if picked == .chest {
                return makeChestRoom(isLocked: chestLocked)
            }
            return makeEventRoom()
        }()

        return [optionA, optionB, special]
    }
    
    // MARK: - Room Factories
    
    private func makeCombatRoom() -> RoomOption {
        let enemy = RuntimeEnemyKind.allCases.randomElement() ?? .punisher
        let desc = combatDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .combat,
            isLocked: false,
            difficulty: 1,
            descriptionText: desc,
            previewEnemy: enemy
        )
    }
    
    private func makeEliteRoom() -> RoomOption {
        let enemy = RuntimeEnemyKind.allCases.randomElement() ?? .graphiteGolem
        let desc = eliteDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .elite,
            isLocked: false,
            difficulty: 2,
            descriptionText: desc,
            previewEnemy: enemy
        )
    }
    
    private func makeBossRoom(actIndex: Int) -> RoomOption {
        // Boss depends on act
        let bossEnemy: RuntimeEnemyKind = {
            switch actIndex {
            case 1: return .punisher
            case 2: return .zesurumiMonks
            default: return .feyanchа
            }
        }()
        let desc = bossDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .boss,
            isLocked: false,
            difficulty: 3,
            descriptionText: desc,
            previewEnemy: bossEnemy
        )
    }
    
    private func makeEventRoom() -> RoomOption {
        let desc = eventDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .event,
            isLocked: false,
            difficulty: 0,
            descriptionText: desc,
            previewEnemy: nil
        )
    }
    
    private func makeRestRoom() -> RoomOption {
        let desc = restDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .rest,
            isLocked: false,
            difficulty: 0,
            descriptionText: desc,
            previewEnemy: nil
        )
    }
    
    private func makeChestRoom(isLocked: Bool) -> RoomOption {
        let desc = chestDescriptions.randomElement() ?? ""
        return RoomOption(
            kind: .chest,
            isLocked: isLocked,
            difficulty: 0,
            descriptionText: desc,
            previewEnemy: nil
        )
    }
}
