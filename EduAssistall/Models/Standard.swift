import Foundation

enum StandardFramework: String, Codable, CaseIterable {
    case commonCore  = "common_core"
    case ngss        = "ngss"
    case state       = "state_standard"

    var displayName: String {
        switch self {
        case .commonCore: return "Common Core"
        case .ngss:       return "Next Gen Science"
        case .state:      return "State Standard"
        }
    }
}

struct Standard: Codable, Identifiable {
    var id: String
    var code: String           // e.g. "CCSS.MATH.6.NS.A.1"
    var description: String
    var subject: String
    var gradeLevel: String
    var framework: StandardFramework
}
