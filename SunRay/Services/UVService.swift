import Foundation
import CoreLocation
import WeatherKit

// Toggle this flag in Build Settings -> Other Swift Flags: add `-D USE_WEATHERKIT_STUB` to enable the stub.

struct UVService {
    
    enum UVError: Error { case unavailable }
    
    // Returns (uvIndex, cloudCover 0..1) using WeatherKit when available.
    func currentUV(for location: CLLocation) async throws -> (Double, Double) {
#if USE_WEATHERKIT_STUB
    // Temporary stub to verify UI wiring independent of WeatherKit
    return (5.6, 0.25)
#else
    if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
        let weather = try await WeatherService.shared.weather(for: location)
        let uvValue = Double(weather.currentWeather.uvIndex.value)
        let cloud = weather.currentWeather.cloudCover ?? 0.3
        return (uvValue, cloud)
    } else {
        // Fallback stub for older OS versions: simple diurnal estimate
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let hour = Double(comps.hour ?? 12) + Double(comps.minute ?? 0) / 60.0
        let uv = max(0, 10.0 * sin((hour - 6.0) / 12.0 * .pi)) // 0 at ~6am/6pm, ~10 at noon
        let cloud = 0.3
        return (uv, cloud)
    }
#endif
    }
}

