import Foundation

enum GradeBand: String, Codable, CaseIterable, Identifiable {
    case kTo2  = "K-2"
    case threeToFive = "3-5"
    case sixToEight  = "6-8"
    case nineTo12    = "9-12"

    var id: String { rawValue }

    var displayName: String { rawValue }

    /// Returns the GradeBand for a given grade string ("K","1"…"12").
    static func from(grade: String) -> GradeBand {
        switch grade.uppercased() {
        case "K", "1", "2":              return .kTo2
        case "3", "4", "5":              return .threeToFive
        case "6", "7", "8":              return .sixToEight
        default:                          return .nineTo12
        }
    }
}

struct DistrictConfig: Codable, Identifiable {
    var id: String              // districtId
    var districtName: String
    var blockedTopics: [String]                   // applies to all grade bands
    var gradeBandTopics: [String: [String]]        // keyed by GradeBand.rawValue
    var counselorIds: [String]
    var updatedAt: Date

    init(id: String, districtName: String = "") {
        self.id = id
        self.districtName = districtName
        self.blockedTopics = []
        self.gradeBandTopics = Dictionary(
            uniqueKeysWithValues: GradeBand.allCases.map { ($0.rawValue, [String]()) }
        )
        self.counselorIds = []
        self.updatedAt = Date()
    }

    /// Merged blocked topics for a specific grade band: district-wide + band-specific.
    func blockedTopics(for band: GradeBand) -> [String] {
        let bandSpecific = gradeBandTopics[band.rawValue] ?? []
        return Array(Set(blockedTopics + bandSpecific))
    }
}
