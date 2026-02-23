import Foundation

enum VitaminDModel {
    // Scale factor for the Michaelis-Menten UV saturation model.
    // Calibrated so that UV=5, Type III skin, SPF 1, 25% exposed, clear sky, age ≤20
    // yields ~562 IU per 30 min — consistent with the Holick (2007) midday reference.
    // Ref: Holick MF. N Engl J Med. 2007;357(3):266-281.
    static let baseIUPerMinute: Double = 60

    // Michaelis-Menten saturation curve for UV response.
    // Models diminishing returns as UV index rises — skin can only absorb so much UVB
    // before the conversion rate plateaus. Factor = 1.0 at UV≈2, approaches 3.0 asymptotically.
    // More physiologically accurate than a linear model at high UV values (8+).
    // Ref: Engelsen O. Photochem Photobiol Sci. 2010;9(3):369-379.
    static func uvSaturationFactor(_ uvIndex: Double) -> Double {
        (uvIndex * 3.0) / (4.0 + uvIndex)
    }

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

    // Age-related decline in cutaneous vitamin D synthesis.
    // Synthesis peaks before age 20 and declines ~1.5% per year thereafter,
    // reaching ~25% of peak capacity by age 70 (floor).
    // Ref: MacLaughlin J, Holick MF. J Clin Invest. 1985;76(4):1536-1538.
    static func ageFactor(for age: Int) -> Double {
        if age <= 20 { return 1.0 }
        if age >= 70 { return 0.25 }
        return max(0.25, 1.0 - Double(age - 20) * 0.015)
    }

    static func estimateSynthesizedIU(
        uvIndex: Double,
        minutes: Double,
        cloudCover: Double,
        skinType: FitzpatrickSkinType,
        spf: Int,
        exposedPercent: Double,
        age: Int = 20
    ) -> Double {
        guard uvIndex > 0, minutes > 0, exposedPercent > 0 else { return 0 }
        let uvFactor = uvSaturationFactor(uvIndex)
        let spfFactor = attenuationForSPF(spf)
        let cloudFactor = cloudCoverFactor(cloudCover)
        let skinFactor = skinType.synthesisFactor
        let areaFactor = max(0, min(1, exposedPercent / 100.0))
        let ageF = ageFactor(for: age)
        let iuPerMinute = baseIUPerMinute * uvFactor * spfFactor * cloudFactor * skinFactor * areaFactor * ageF
        return max(0, iuPerMinute * minutes)
    }

    static func recommendedMinutesToGoal(
        currentUV: Double,
        cloudCover: Double,
        settings: UserSettings
    ) -> Double {
        guard currentUV > 0 else { return .infinity }
        let uvFactor = uvSaturationFactor(currentUV)
        let spfFactor = attenuationForSPF(settings.defaultSPF)
        let cloudFactor = cloudCoverFactor(cloudCover)
        let skinFactor = settings.skinType.synthesisFactor
        let areaFactor = max(0, min(1, settings.defaultExposedPercent / 100.0))
        let ageF = ageFactor(for: settings.age)
        let iuPerMinute = baseIUPerMinute * uvFactor * spfFactor * cloudFactor * skinFactor * areaFactor * ageF
        guard iuPerMinute > 0 else { return .infinity }
        return settings.dailyGoalIU / iuPerMinute
    }
}
