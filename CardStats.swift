import Foundation

struct CardStats: Codable, Equatable {
    var timesUsed: Int = 0
    
    mutating func incrementUsage() {
        timesUsed += 1
    }
}
