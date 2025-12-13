import XCTest
@testable import SunRay

final class VitaminDModelTests: XCTestCase {

    func testZeroUVReturnsZero() {
        let iu = VitaminDModel.estimateSynthesizedIU(uvIndex: 0, minutes: 30, cloudCover: 0, skinType: .III, spf: 15, exposedPercent: 25)
        XCTAssertEqual(iu, 0)
    }

    func testHighCloudReducesSynthesis() {
        let iuLowCloud = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0.0, skinType: .III, spf: 15, exposedPercent: 25)
        let iuHighCloud = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 1.0, skinType: .III, spf: 15, exposedPercent: 25)
        XCTAssertTrue(iuHighCloud < iuLowCloud)
    }

    func testSPFClamping() {
        let iuSPF0 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0.0, skinType: .III, spf: 0, exposedPercent: 25)
        let iuSPF1 = VitaminDModel.estimateSynthesizedIU(uvIndex: 5, minutes: 30, cloudCover: 0.0, skinType: .III, spf: 1, exposedPercent: 25)
        XCTAssertEqual(iuSPF0, iuSPF1)
    }

    func testRecommendedMinutesFinite() {
        let minutes = VitaminDModel.recommendedMinutesToGoal(currentUV: 5, cloudCover: 0.2, settings: UserSettings())
        XCTAssert(minutes.isFinite && minutes > 0)
    }
}
