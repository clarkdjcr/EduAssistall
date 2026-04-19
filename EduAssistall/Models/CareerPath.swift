import Foundation
import SwiftUI

// MARK: - Education Option

enum EducationType: String, Codable, CaseIterable {
    case college     = "college"
    case technical   = "technical"
    case vocational  = "vocational"
    case selfTaught  = "self_taught"

    var displayName: String {
        switch self {
        case .college:    return "College / University"
        case .technical:  return "Technical Program"
        case .vocational: return "Vocational / Trade"
        case .selfTaught: return "Self-Taught / Online"
        }
    }

    var icon: String {
        switch self {
        case .college:    return "building.columns.fill"
        case .technical:  return "wrench.and.screwdriver.fill"
        case .vocational: return "hammer.fill"
        case .selfTaught: return "laptopcomputer"
        }
    }

    var color: Color {
        switch self {
        case .college:    return .blue
        case .technical:  return .orange
        case .vocational: return .brown
        case .selfTaught: return .purple
        }
    }
}

struct EducationOption: Identifiable, Codable {
    var id: String
    var type: EducationType
    var name: String
    var duration: String
    var estimatedAnnualCost: Int    // USD per year
    var description: String

    var formattedCost: String {
        estimatedAnnualCost == 0
            ? "Free / low cost"
            : "$\(estimatedAnnualCost / 1000)K / year"
    }
}

// MARK: - Career Path

struct CareerPath: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var relatedInterests: [String]
    var educationOptions: [EducationOption]
    var averageSalary: String
    var growthOutlook: String
    var icon: String        // SF Symbol name
    var colorName: String   // "blue", "green", etc.

    var color: Color {
        switch colorName {
        case "blue":   return .blue
        case "green":  return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red":    return .red
        case "teal":   return .teal
        case "mint":   return .mint
        case "indigo": return .indigo
        case "cyan":   return .cyan
        case "brown":  return .brown
        default:       return .blue
        }
    }

    func matchScore(interests: [String]) -> Int {
        let lower = interests.map { $0.lowercased() }
        return relatedInterests.filter { lower.contains($0.lowercased()) }.count
    }
}
