struct ChestState: Codable {
    var isOpened: Bool = false
    var revealed: Artifact? = nil
}
