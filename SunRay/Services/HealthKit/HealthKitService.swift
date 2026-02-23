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

    private var vitaminDType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)
    }

    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        guard let uv = uvExposureType, let vitD = vitaminDType else {
            SRLog("HealthKitService: required quantity types unavailable", level: .error)
            return false
        }

        let toShare: Set<HKSampleType> = [uv, vitD]
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

    // Saves estimated vitamin D synthesis as a dietary sample.
    // 1 IU of vitamin D₃ = 0.025 mcg; HealthKit stores dietary vitamin D in micrograms.
    func saveVitaminD(estimatedIU: Double, start: Date, end: Date) async throws {
        guard let vitDType = vitaminDType else { throw HealthKitError.unavailableType }
        guard estimatedIU > 0 else { return }

        let micrograms = estimatedIU * 0.025
        let unit = HKUnit.gramUnit(with: .micro)
        let quantity = HKQuantity(unit: unit, doubleValue: micrograms)

        let metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: false,
            "com.sunray.estimatedIU": estimatedIU,
            "com.sunray.source": "Calculated from UV exposure"
        ]

        let sample = HKQuantitySample(
            type: vitDType,
            quantity: quantity,
            start: start,
            end: end,
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
