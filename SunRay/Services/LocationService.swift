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
        Task { await reverseGeocode(loc) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent for MVP
    }

    private func reverseGeocode(_ location: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            placemark = placemarks.first
        } catch {
            placemark = nil
        }
    }
}
