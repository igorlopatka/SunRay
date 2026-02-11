import Foundation

enum VitaminDModel {
    // Approximate IU of vitamin D₃ synthesized per minute at UV index 1,
    // fair skin (Type I), no sunscreen, full-body exposure.
    // Derived from Holick (2007): ~1000 IU in 10-15 min of midday summer sun
    // (UV ~6-8) for Type I-III with ~25% body exposed, which back-calculates
    // to roughly 15-25 IU/min/UV-index. We use 20 as a central estimate.
    // Ref: Holick MF. N Engl J Med. 2007;357(3):266-281.
    static let baseIUPerMinuteAtUV1: Double = 20

    // SPF attenuation: SPF N blocks (1 - 1/N) of UVB.
    // Ref: Matsuoka LY et al. J Clin Endocrinol Metab. 1987;64(6):1165-1168.
    static func attenuationForSPF(_ spf: Int) -> Double {
        let safeSPF = max(1, spf)
        return 1.0 / Double(safeSPF)
    }

    // Cloud attenuation of UVB radiation.
    // Overcast skies transmit 10-30% of UVB depending on cloud type/thickness.
    // We model a linear reduction of 75% at full cloud cover (factor 0.25),
    // with a 10% floor for extremely thick cover.
    // Ref: Calbó J et al. J Appl Meteorol Climatol. 2005;44(10):1506-1512.
    static func cloudCoverFactor(_ cloudCover: Double) -> Double {
        max(0.1, 1.0 - 0.75 * cloudCover)
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

