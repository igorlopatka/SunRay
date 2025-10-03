import Foundation

enum VitaminDModel {
    static let baseIUPerMinuteAtUV1: Double = 20

    static func attenuationForSPF(_ spf: Int) -> Double {
        guard spf > 1 else { return 1.0 }
        return 1.0 / Double(spf)
    }

    static func solarElevationFactor(_ degrees: Double) -> Double {
        max(0, min(1, degrees / 60.0))
    }

    static func cloudCoverFactor(_ cloudCover: Double) -> Double {
        max(0.3, 1.0 - 0.5 * cloudCover)
    }

    static func estimateSynthesizedIU(
        uvIndex: Double,
        minutes: Double,
        solarElevation: Double,
        cloudCover: Double,
        skinType: FitzpatrickSkinType,
        spf: Int,
        exposedPercent: Double
    ) -> Double {
        guard uvIndex > 0, minutes > 0, exposedPercent > 0 else { return 0 }
        let spfFactor = attenuationForSPF(spf)
        let elevationFactor = solarElevationFactor(solarElevation)
        let cloudFactor = cloudCoverFactor(cloudCover)
        let skinFactor = skinType.synthesisFactor
        let areaFactor = max(0, min(1, exposedPercent / 100.0))
        let iuPerMinute = baseIUPerMinuteAtUV1 * uvIndex * spfFactor * elevationFactor * cloudFactor * skinFactor * areaFactor
        return max(0, iuPerMinute * minutes)
    }

    static func recommendedMinutesToGoal(
        currentUV: Double,
        solarElevation: Double,
        cloudCover: Double,
        settings: UserSettings
    ) -> Double {
        guard currentUV > 0 else { return .infinity }
        let spfFactor = attenuationForSPF(settings.defaultSPF)
        let elevationFactor = solarElevationFactor(solarElevation)
        let cloudFactor = cloudCoverFactor(cloudCover)
        let skinFactor = settings.skinType.synthesisFactor
        let areaFactor = max(0, min(1, settings.defaultExposedPercent / 100.0))
        let iuPerMinute = baseIUPerMinuteAtUV1 * currentUV * spfFactor * elevationFactor * cloudFactor * skinFactor * areaFactor
        guard iuPerMinute > 0 else { return .infinity }
        return settings.dailyGoalIU / iuPerMinute
    }
}
