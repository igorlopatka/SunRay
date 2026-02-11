import Foundation
import HealthKit
import CoreLocation
import os

enum HealthKitError: Error {
    case unavailableType
}

final class HealthKitService: HealthKitProviding {

    private let store = HKHealthStore()

    private var uvExposureType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .uvExposure)
    }

    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        guard let uv = uvExposureType else {
            SRLog("HealthKitService: required quantity types unavailable", level: .error)
            return false
        }

        let toShare: Set<HKSampleType> = [uv]
        let toRead: Set<HKObjectType> = []

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
            "com.sunray.durationMinutes": durationMinutes
        ]

        if let loc = location {
            metadata["com.sunray.latitude"] = loc.coordinate.latitude
            metadata["com.sunray.longitude"] = loc.coordinate.longitude
            metadata["com.sunray.horizontalAccuracy"] = loc.horizontalAccuracy
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
}
