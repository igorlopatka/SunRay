import Foundation
import HealthKit
import CoreLocation

enum HealthKitError: Error {
    case unavailableType
}

final class HealthKitService: HealthKitProviding {

    private let store = HKHealthStore()

    private var uvExposureType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .uvExposure)
    }

    private var dietaryVitaminDType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)
    }

    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        guard let uv = uvExposureType, let dietary = dietaryVitaminDType else {
            print("HealthKitService: required quantity types unavailable")
            return false
        }

        let toShare: Set<HKSampleType> = [uv]
        let toRead: Set<HKObjectType> = [dietary]

        return try await withCheckedThrowingContinuation { continuation in
            store.requestAuthorization(toShare: toShare, read: toRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    func saveUVExposure(durationMinutes: Int, uvIndex: Double, location: CLLocation?) async throws {
        guard let uvType = uvExposureType else { throw HealthKitError.unavailableType }
        guard durationMinutes > 0, uvIndex.isFinite, uvIndex > 0 else { return }

        let unit = HKUnit.count()
        let quantity = HKQuantity(unit: unit, doubleValue: uvIndex)

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-TimeInterval(durationMinutes * 60))

        var metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: true,
            "com.sunseeker.durationMinutes": durationMinutes
        ]

        if let loc = location {
            metadata["com.sunseeker.latitude"] = loc.coordinate.latitude
            metadata["com.sunseeker.longitude"] = loc.coordinate.longitude
            metadata["com.sunseeker.horizontalAccuracy"] = loc.horizontalAccuracy
        }

        let sample = HKQuantitySample(
            type: uvType,
            quantity: quantity,
            start: startDate,
            end: endDate,
            metadata: metadata
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.save(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func readTodayDietaryVitaminD() async throws -> Double {
        guard let dietary = dietaryVitaminDType else { throw HealthKitError.unavailableType }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: dietary,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let unit = HKUnit.internationalUnit()
                let total = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: total)
            }
            store.execute(query)
        }
    }
}
