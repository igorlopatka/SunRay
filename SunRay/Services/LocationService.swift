import Foundation
import CoreLocation
import Contacts
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var location: CLLocation?
    @Published private(set) var placemark: CLPlacemark?

    var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestAuthorization() async throws {
        guard CLLocationManager.locationServicesEnabled() else {
            throw NSError(domain: "Location", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location services disabled"])
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Let delegate callback handle subsequent flow.
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            throw NSError(domain: "Location", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location permission denied"])
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        location = loc
        onLocationUpdate?(loc)

        // Run reverse geocoding off the main actor to avoid UI stalls.
        Task.detached { [weak self] in
            guard let placemark = try? await Self.reverseGeocodeOffMain(loc) else { return }
            await MainActor.run {
                self?.placemark = placemark
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent for MVP
    }

    // Nonisolated helper that runs off the main actor.
    nonisolated private static func reverseGeocodeOffMain(_ location: CLLocation) async throws -> CLPlacemark? {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        return placemarks.first
    }
}
