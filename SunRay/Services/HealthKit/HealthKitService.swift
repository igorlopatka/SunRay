import Foundation
import HealthKit
import CoreLocation

final class HealthKitService: HealthKitProviding {

    private let store = HKHealthStore()

    private var uvExposureType: HKQuantityType {
        // UV Index is a dimensionless quantity in HealthKit.
        HKObjectType.quantityType(forIdentifier: .uvExposure)!
    }

    private var dietaryVitaminDType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)!
    }

    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let toShare: Set<HKSampleType> = [uvExposureType]
        let toRead: Set<HKObjectType> = [dietaryVitaminDType]

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
        guard durationMinutes > 0, uvIndex.isFinite, uvIndex > 0 else { return }

        // HealthKit represents UV exposure as a quantity with "count" (dimensionless) unit.
        let unit = HKUnit.count()
        let quantity = HKQuantity(unit: unit, doubleValue: uvIndex)

        // Use the session window as the sample’s time range. Since the protocol only
        // provides duration, we backdate from "now". If you later pass start/end, use those.
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-TimeInterval(durationMinutes * 60))

        var metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: true,
            "com.sunseeker.durationMinutes": durationMinutes
        ]

        if let loc = location {
            // HealthKit quantity samples don’t support attaching a route directly.
            // You can store coarse location in metadata, or graduate to HKWorkout + HKWorkoutRoute.
            metadata["com.sunseeker.latitude"] = loc.coordinate.latitude
            metadata["com.sunseeker.longitude"] = loc.coordinate.longitude
            metadata["com.sunseeker.horizontalAccuracy"] = loc.horizontalAccuracy
        }

        let sample = HKQuantitySample(
            type: uvExposureType,
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
        // Build predicate for "today" in the user’s current calendar/locale
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        // Sum dietary vitamin D samples for today
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: dietaryVitaminDType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let unit = HKUnit.internationalUnit() // IU
                let total = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: total)
            }
            store.execute(query)
        }
    }
}
