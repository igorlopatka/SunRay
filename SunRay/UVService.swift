import Foundation
import CoreLocation

struct UVService {
    enum UVError: Error { case unavailable }

    // Returns (uvIndex, cloudCover 0..1)
    func currentUV(for location: CLLocation) async throws -> (Double, Double) {
        // Simple diurnal UV curve stub: peaks mid-day
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let hour = Double(comps.hour ?? 12) + Double(comps.minute ?? 0) / 60.0
        let uv = max(0, 10.0 * sin((hour - 6.0) / 12.0 * .pi)) // 0 at ~6am/6pm, ~10 at noon
        let cloud = 0.3 // 30% clouds stub
        return (uv, cloud)
    }
}
