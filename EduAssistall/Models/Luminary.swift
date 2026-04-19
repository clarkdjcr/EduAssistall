import Foundation

struct Luminary: Identifiable, Codable {
    var id: String
    var name: String
    var field: String
    var bio: String
    var quote: String
    var relatedInterests: [String]
    var icon: String        // SF Symbol for their field

    func matchScore(interests: [String]) -> Int {
        let lower = interests.map { $0.lowercased() }
        return relatedInterests.filter { lower.contains($0.lowercased()) }.count
    }
}
