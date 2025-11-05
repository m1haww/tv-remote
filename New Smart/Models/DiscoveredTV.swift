import Foundation

struct DiscoveredTV: Identifiable, Equatable {
    let id: String
    let name: String
    let manufacturer: String
    let ipAddress: String
    let modelName: String?
    let macAddress: String?
    
    var brandIcon: String {
        return "cast"
    }
}
