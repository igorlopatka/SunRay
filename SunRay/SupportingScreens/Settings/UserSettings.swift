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

struct UserSettings: Codable, Equatable {
    var skinType: FitzpatrickSkinType = .III
    var age: Int = 30
    var defaultSPF: Int = 15
    var defaultExposedPercent: Double = 25 // %
    var dailyGoalIU: Double = 800 // IU
}
