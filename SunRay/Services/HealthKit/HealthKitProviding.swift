import Foundation
import CoreLocation

protocol HealthKitProviding {
    func requestAuthorization() async throws -> Bool
    func saveUVExposure(durationMinutes: Int, uvIndex: Double, location: CLLocation?) async throws
}

struct NoOpHealthKitService: HealthKitProviding {
    func requestAuthorization() async throws -> Bool { false }
    func saveUVExposure(durationMinutes: Int, uvIndex: Double, location: CLLocation?) async throws { }
}
