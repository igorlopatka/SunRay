import Foundation

enum FitzpatrickSkinType: String, CaseIterable, Codable, Identifiable {
    case I, II, III, IV, V, VI
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .I: return "Type I (Very fair)"
        case .II: return "Type II (Fair)"
        case .III: return "Type III (Medium)"
        case .IV: return "Type IV (Olive)"
        case .V: return "Type V (Brown)"
        case .VI: return "Type VI (Dark brown/black)"
        }
    }

    // Relative vitamin D synthesis efficiency by skin type.
    // Higher melanin absorbs more UVB, reducing previtamin D₃ production.
    // Factors approximate the relative dose needed to produce equivalent
    // serum 25(OH)D levels across Fitzpatrick types.
    // Ref: Clemens TL et al. Lancet. 1982;1(8263):74-76.
    // Ref: Chen TC et al. J Clin Endocrinol Metab. 2007;92(6):2130-2135.
    var synthesisFactor: Double {
        switch self {
        case .I: return 1.0
        case .II: return 0.9
        case .III: return 0.75
        case .IV: return 0.6
        case .V: return 0.45
        case .VI: return 0.35
        }
    }
}

// Clothing coverage levels mapped to approximate exposed skin percentage.
// Matches the real-world intuition of what people are wearing rather than
// asking users to estimate an abstract percentage.
enum ClothingLevel: String, CaseIterable, Codable, Identifiable {
    case minimal   // swimwear
    case light     // t-shirt + shorts
    case moderate  // t-shirt + pants
    case heavy     // long sleeves + pants
    case full      // full coverage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal:  return "Minimal (swimwear)"
        case .light:    return "Light (t-shirt + shorts)"
        case .moderate: return "Moderate (t-shirt + pants)"
        case .heavy:    return "Heavy (long sleeves + pants)"
        case .full:     return "Full coverage"
        }
    }

    var shortName: String {
        switch self {
        case .minimal:  return "Minimal"
        case .light:    return "Light"
        case .moderate: return "Moderate"
        case .heavy:    return "Heavy"
        case .full:     return "Full"
        }
    }

    // Approximate exposed body surface area for vitamin D synthesis.
    var exposedPercent: Double {
        switch self {
        case .minimal:  return 80
        case .light:    return 50
        case .moderate: return 25
        case .heavy:    return 10
        case .full:     return 5
        }
    }
}

struct UserSettings: Codable, Equatable {
    var skinType: FitzpatrickSkinType = .III
    var age: Int = 30
    var defaultSPF: Int = 15
    var defaultClothing: ClothingLevel = .moderate
    var dailyGoalIU: Double = 800 // IU

    init() {}

    // Forward-compatible decoding: missing keys fall back to the declared
    // defaults rather than throwing. This means adding new fields to this
    // struct in a future release never breaks existing installs where the
    // saved JSON predates the field.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        skinType     = try c.decodeIfPresent(FitzpatrickSkinType.self, forKey: .skinType)     ?? .III
        age          = try c.decodeIfPresent(Int.self,                 forKey: .age)          ?? 30
        defaultSPF   = try c.decodeIfPresent(Int.self,                 forKey: .defaultSPF)   ?? 15
        defaultClothing = try c.decodeIfPresent(ClothingLevel.self,    forKey: .defaultClothing) ?? .moderate
        dailyGoalIU  = try c.decodeIfPresent(Double.self,              forKey: .dailyGoalIU)  ?? 800
    }
}
