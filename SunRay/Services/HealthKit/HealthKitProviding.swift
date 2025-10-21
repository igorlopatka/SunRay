import Foundation
import CoreLocation

protocol HealthKitProviding {
    func requestAuthorization() async throws -> Bool
    func saveUVExposure(durationMinutes: Int, uvIndex: Double, location: CLLocation?) async throws
    func readTodayDietaryVitaminD() async throws -> Double
}

struct NoOpHealthKitService: HealthKitProviding {
    func requestAuthorization() async throws -> Bool { false }
    func saveUVExposure(durationMinutes: Int, uvIndex: Double, location: CLLocation?) async throws { }
    func readTodayDietaryVitaminD() async throws -> Double { 0 }
}
