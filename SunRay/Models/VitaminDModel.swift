import Foundation

enum VitaminDModel {
    static let baseIUPerMinuteAtUV1: Double = 20

    static func attenuationForSPF(_ spf: Int) -> Double {
        let safeSPF = max(1, spf)
        return 1.0 / Double(safeSPF)
    }

    static func cloudCoverFactor(_ cloudCover: Double) -> Double {
        max(0.3, 1.0 - 0.5 * cloudCover)
    }

    static func estimateSynthesizedIU(
        uvIndex: Double,
        minutes: Double,
        cloudCover: Double,
        skinType: FitzpatrickSkinType,
        spf: Int,
        exposedPercent: Double
    ) -> Double {
        guard uvIndex > 0, minutes > 0, exposedPercent > 0 else { return 0 }
        let spfFactor = attenuationForSPF(spf)
        let cloudFactor = cloudCoverFactor(cloudCover)
        let skinFactor = skinType.synthesisFactor
        let areaFactor = max(0, min(1, exposedPercent / 100.0))
        let iuPerMinute = baseIUPerMinuteAtUV1 * uvIndex * spfFactor * cloudFactor * skinFactor * areaFactor
        return max(0, iuPerMinute * minutes)
    }

    static func recommendedMinutesToGoal(
        currentUV: Double,
        cloudCover: Double,
        settings: UserSettings
    ) -> Double {
        guard currentUV > 0 else { return .infinity }
        let spfFactor = attenuationForSPF(settings.defaultSPF)
        let cloudFactor = cloudCoverFactor(cloudCover)
        let skinFactor = settings.skinType.synthesisFactor
        let areaFactor = max(0, min(1, settings.defaultExposedPercent / 100.0))
        let iuPerMinute = baseIUPerMinuteAtUV1 * currentUV * spfFactor * cloudFactor * skinFactor * areaFactor
        guard iuPerMinute > 0 else { return .infinity }
        return settings.dailyGoalIU / iuPerMinute
    }
}

