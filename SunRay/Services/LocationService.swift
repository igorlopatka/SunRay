import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var location: CLLocation?
    @Published private(set) var placemark: CLPlacemark?

    // Optional callback for consumers that want push-style updates
    var onLocationUpdate: ((CLLocation) -> Void)?

    // Continuations to await delegate callbacks
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var oneShotLocationContinuation: CheckedContinuation<CLLocation, Error>?

    // Throttling for reverse geocoding
    private var lastGeocodedLocation: CLLocation?
    private var lastGeocodeDate: Date?
    private let geocodeMinDistance: CLLocationDistance = 500 // meters
    private let geocodeMinInterval: TimeInterval = 10 * 60    // seconds

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 200 // meters
        manager.pausesLocationUpdatesAutomatically = true
    }

    // Public API

    func requestAuthorization() async throws {
        guard CLLocationManager.locationServicesEnabled() else {
            throw NSError(domain: "Location", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location services are disabled"])
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            let status = await withCheckedContinuation { (continuation: CheckedContinuation<CLAuthorizationStatus, Never>) in
                self.authContinuation = continuation
                self.manager.requestWhenInUseAuthorization()
            }
            authorizationStatus = status
            try handlePostAuthorization(status: status)

        case .authorizedAlways, .authorizedWhenInUse:
            authorizationStatus = manager.authorizationStatus
            startUpdating()
            // Also request a one-shot to speed up first fix
            _ = try? await requestSingleLocation()

        case .denied, .restricted:
            authorizationStatus = manager.authorizationStatus
            throw NSError(domain: "Location", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location permission denied or restricted"])

        @unknown default:
            authorizationStatus = manager.authorizationStatus
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationStatus = status

        // Resume any waiting authorization continuation
        if let cont = authContinuation {
            authContinuation = nil
            cont.resume(returning: status)
        }

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdating()
            // Prime a quick fix if we don't have one
            if location == nil {
                Task {
                    _ = try? await requestSingleLocation()
                }
            }
        case .denied, .restricted:
            // Clear stale data when access is lost
            location = nil
            placemark = nil
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        // Fulfill one-shot continuation if present
        if let cont = oneShotLocationContinuation {
            oneShotLocationContinuation = nil
            cont.resume(returning: loc)
        }

        location = loc
        onLocationUpdate?(loc)

        maybeReverseGeocode(for: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Fulfill one-shot continuation with error
        if let cont = oneShotLocationContinuation {
            oneShotLocationContinuation = nil
            cont.resume(throwing: error)
        }
        // For MVP, we keep this silent; you may publish an alert if desired.
    }

    // MARK: - Helpers

    private func startUpdating() {
        // Use continuous updates with a reasonable distance filter
        manager.startUpdatingLocation()
    }

    private func handlePostAuthorization(status: CLAuthorizationStatus) throws {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdating()
            Task {
                _ = try? await requestSingleLocation()
            }
        case .denied, .restricted:
            throw NSError(domain: "Location", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location permission denied or restricted"])
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    private func requestSingleLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            self.oneShotLocationContinuation = continuation
            self.manager.requestLocation()
        }
    }

    private func maybeReverseGeocode(for loc: CLLocation) {
        let now = Date()
        let shouldGeocodeByDistance: Bool
        if let last = lastGeocodedLocation {
            shouldGeocodeByDistance = loc.distance(from: last) >= geocodeMinDistance
        } else {
            shouldGeocodeByDistance = true
        }
        let shouldGeocodeByTime = (lastGeocodeDate == nil) || (now.timeIntervalSince(lastGeocodeDate!) >= geocodeMinInterval)

        guard shouldGeocodeByDistance || shouldGeocodeByTime else { return }

        lastGeocodedLocation = loc
        lastGeocodeDate = now

        // Run reverse geocoding off the main actor to avoid blocking UI.
        Task.detached { [weak self] in
            guard let placemark = try? await Self.reverseGeocodeOffMain(loc) else { return }
            await MainActor.run {
                self?.placemark = placemark
            }
        }
    }

    // Nonisolated helper that runs off the main actor.
    nonisolated private static func reverseGeocodeOffMain(_ location: CLLocation) async throws -> CLPlacemark? {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        return placemarks.first
    }
}
