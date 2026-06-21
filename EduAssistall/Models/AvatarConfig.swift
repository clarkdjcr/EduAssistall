import Foundation
import SwiftUI

// Phase 2: Avatar customization system
struct AvatarConfig: Codable, Equatable {
    var bodyType: BodyType
    var skinTone: SkinTone
    var hairStyle: HairStyle
    var hairColor: HairColor
    var accessories: [AvatarAccessory]
    var background: AvatarBackground
    
    init(bodyType: BodyType = .average, skinTone: SkinTone = .medium, hairStyle: HairStyle = .short, 
         hairColor: HairColor = .brown, accessories: [AvatarAccessory] = [], background: AvatarBackground = .blue) {
        self.bodyType = bodyType
        self.skinTone = skinTone
        self.hairStyle = hairStyle
        self.hairColor = hairColor
        self.accessories = accessories
        self.background = background
    }
}

enum BodyType: String, Codable, CaseIterable {
    case slim = "slim"
    case average = "average"
    case athletic = "athletic"
    
    var displayName: String {
        switch self {
        case .slim: return "Slim"
        case .average: return "Average"
        case .athletic: return "Athletic"
        }
    }
}

enum SkinTone: String, Codable, CaseIterable {
    case light = "light"
    case mediumLight = "medium_light"
    case medium = "medium"
    case mediumDark = "medium_dark"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .mediumLight: return "Medium Light"
        case .medium: return "Medium"
        case .mediumDark: return "Medium Dark"
        case .dark: return "Dark"
        }
    }
    
    var color: Color {
        switch self {
        case .light: return Color(red: 0.95, green: 0.85, blue: 0.75)
        case .mediumLight: return Color(red: 0.85, green: 0.70, blue: 0.60)
        case .medium: return Color(red: 0.70, green: 0.55, blue: 0.45)
        case .mediumDark: return Color(red: 0.55, green: 0.40, blue: 0.30)
        case .dark: return Color(red: 0.35, green: 0.25, blue: 0.20)
        }
    }
}

enum HairStyle: String, Codable, CaseIterable {
    case short = "short"
    case medium = "medium"
    case long = "long"
    case curly = "curly"
    case bald = "bald"
    
    var displayName: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        case .curly: return "Curly"
        case .bald: return "Bald"
        }
    }
}

enum HairColor: String, Codable, CaseIterable {
    case black = "black"
    case brown = "brown"
    case blonde = "blonde"
    case red = "red"
    case gray = "gray"
    
    var displayName: String {
        switch self {
        case .black: return "Black"
        case .brown: return "Brown"
        case .blonde: return "Blonde"
        case .red: return "Red"
        case .gray: return "Gray"
        }
    }
    
    var color: Color {
        switch self {
        case .black: return .black
        case .brown: return Color(red: 0.4, green: 0.25, blue: 0.1)
        case .blonde: return Color(red: 0.9, green: 0.8, blue: 0.5)
        case .red: return Color(red: 0.7, green: 0.3, blue: 0.2)
        case .gray: return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
}

enum AvatarAccessory: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case glasses = "glasses"
    case hatBaseball = "hat_baseball"
    case hatBeanie = "hat_beanie"
    case headphones = "headphones"
    case bowtie = "bowtie"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .glasses: return "Glasses"
        case .hatBaseball: return "Baseball Cap"
        case .hatBeanie: return "Beanie"
        case .headphones: return "Headphones"
        case .bowtie: return "Bowtie"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "circle"
        case .glasses: return "eyeglasses"
        case .hatBaseball: return "cap.fill"
        case .hatBeanie: return "hat.fill"
        case .headphones: return "headphones"
        case .bowtie: return "bowtie"
        }
    }
    
    var unlockLevel: Int? {
        switch self {
        case .none: return nil
        case .glasses: return 2
        case .hatBaseball: return 5
        case .hatBeanie: return 8
        case .headphones: return 12
        case .bowtie: return 15
        }
    }
}

enum AvatarBackground: String, Codable, CaseIterable {
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case orange = "orange"
    case pink = "pink"
    case teal = "teal"
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .purple: return "Purple"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .teal: return "Teal"
        }
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .teal: return .teal
        }
    }
}
