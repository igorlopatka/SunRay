import XCTest
@testable import SunRay

final class VitaminDModelTests: XCTestCase {

    // MARK: - Zero / boundary inputs

    func testZeroUVReturnsZero() {
        let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: 0, minutes: 30, cloudCover: 0, skinType: .III, spf: 15, exposedPercent: 25)
        XCTAssertEqual(iu, 0)
    }

    func testZeroMinutesReturnsZero() {
        let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 0, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        XCTAssertEqual(iu, 0)
    }

    func testZeroExposedPercentReturnsZero() {
        let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 0)
        XCTAssertEqual(iu, 0)
    }

    func testNegativeUVReturnsZero() {
        let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: -1, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        XCTAssertEqual(iu, 0)
    }

    func testNegativeMinutesReturnsZero() {
        let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: -10, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        XCTAssertEqual(iu, 0)
    }

    // MARK: - Cloud cover

    func testHighCloudReducesSynthesis() {
        let iuLowCloud = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0.0, skinType: .III, spf: 15, exposedPercent: 25)
        let iuHighCloud = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 1.0, skinType: .III, spf: 15, exposedPercent: 25)
        XCTAssertTrue(iuHighCloud < iuLowCloud)
    }

    func testFullOvercastAllowsMinimalSynthesis() {
        let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: 10, minutes: 30, cloudCover: 1.0, skinType: .I, spf: 1, exposedPercent: 100)
        XCTAssertGreaterThan(iu, 0, "Even full overcast should allow some synthesis")
    }

    func testCloudFactorClampsAtMinimum() {
        let factor = VitaminDModel.cloudCoverFactor(1.0)
        XCTAssertGreaterThan(factor, 0)
        // Full overcast: 1.0 - 0.75*1.0 = 0.25 → clamped to 0.25
        XCTAssertEqual(factor, 0.25, accuracy: 0.01)
    }

    func testCloudFactorClearSky() {
        let factor = VitaminDModel.cloudCoverFactor(0.0)
        XCTAssertEqual(factor, 1.0, accuracy: 0.01)
    }

    // MARK: - SPF

    func testSPFClamping() {
        let iuSPF0 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0.0, skinType: .III, spf: 0, exposedPercent: 25)
        let iuSPF1 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0.0, skinType: .III, spf: 1, exposedPercent: 25)
        XCTAssertEqual(iuSPF0, iuSPF1)
    }

    func testHigherSPFReducesSynthesis() {
        let iuSPF1 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        let iuSPF30 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .III, spf: 30, exposedPercent: 25)
        XCTAssertTrue(iuSPF30 < iuSPF1)
        // SPF 30 should pass ~1/30th the UV
        XCTAssertEqual(iuSPF30 / iuSPF1, 1.0 / 30.0, accuracy: 0.001)
    }

    // MARK: - Skin type

    func testDarkerSkinReducesSynthesis() {
        let iuTypeI = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .I, spf: 1, exposedPercent: 25)
        let iuTypeVI = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .VI, spf: 1, exposedPercent: 25)
        XCTAssertTrue(iuTypeVI < iuTypeI)
    }

    func testAllSkinTypesProducePositiveIU() {
        for skinType in FitzpatrickSkinType.allCases {
            let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: skinType, spf: 1, exposedPercent: 25)
            XCTAssertGreaterThan(iu, 0, "Skin type \(skinType.rawValue) should produce positive IU")
        }
    }

    // MARK: - Linearity

    func testSynthesisScalesLinearlyWithMinutes() {
        let iu15 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 15, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        let iu30 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        XCTAssertEqual(iu30, iu15 * 2, accuracy: 0.001)
    }

    func testSynthesisScalesLinearlyWithUV() {
        let iuUV3 = VitaminDModel.estimateSynthesizedIU(uvIndex: 3, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        let iuUV6 = VitaminDModel.estimateSynthesizedIU(uvIndex: 6, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        XCTAssertEqual(iuUV6, iuUV3 * 2, accuracy: 0.001)
    }

    // MARK: - Exposed area

    func testExposedPercentClampedAbove100() {
        let iu100 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 100)
        let iu200 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 200)
        XCTAssertEqual(iu100, iu200, "Values above 100% should be clamped")
    }

    // MARK: - Recommended minutes

    func testRecommendedMinutesFinite() {
        let minutes = VitaminDModel.recommendedMinutesToGoal(currentUV: 5, cloudCover: 0.2, settings: UserSettings())
        XCTAssert(minutes.isFinite && minutes > 0)
    }

    func testRecommendedMinutesZeroUVIsInfinite() {
        let minutes = VitaminDModel.recommendedMinutesToGoal(currentUV: 0, cloudCover: 0, settings: UserSettings())
        XCTAssertTrue(minutes.isInfinite)
    }

    func testRecommendedMinutesHigherUVIsShorter() {
        let minutesLowUV = VitaminDModel.recommendedMinutesToGoal(currentUV: 2, cloudCover: 0, settings: UserSettings())
        let minutesHighUV = VitaminDModel.recommendedMinutesToGoal(currentUV: 8, cloudCover: 0, settings: UserSettings())
        XCTAssertTrue(minutesHighUV < minutesLowUV)
    }

    // MARK: - Sanity check: realistic scenario

    func testRealisticScenarioProducesReasonableIU() {
        // Type III skin, SPF 1, 25% exposed, UV 5, clear sky, 30 min
        // Expected: 20 * 5 * 1.0 * 1.0 * 0.75 * 0.25 * 30 = 562.5 IU
        let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0, skinType: .III, spf: 1, exposedPercent: 25)
        XCTAssertEqual(iu, 562.5, accuracy: 0.1)
    }
}
