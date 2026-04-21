import Foundation
import SwiftUI

enum SessionFlagType: String, Codable {
    case frustration
    case offTopic = "off_topic"
    case safety
    case inactivity

    var displayName: String {
        switch self {
        case .frustration: return "Frustration"
        case .offTopic:    return "Off-Topic"
        case .safety:      return "Safety"
        case .inactivity:  return "Inactivity"
        }
    }

    var iconName: String {
        switch self {
        case .frustration: return "exclamationmark.triangle.fill"
        case .offTopic:    return "arrow.uturn.backward.circle.fill"
        case .safety:      return "shield.fill"
        case .inactivity:  return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .frustration: return .orange
        case .offTopic:    return .yellow
        case .safety:      return .red
        case .inactivity:  return .secondary
        }
    }
}

struct SessionFlag: Identifiable, Codable {
    var id: String
    var studentId: String
    var type: SessionFlagType
    var reason: String
    var messagePreview: String?
    var acknowledged: Bool
    var createdAt: Date
}
