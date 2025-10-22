import Foundation
import CoreLocation
import WeatherKit

struct UVService {
    
    enum UVError: Error { case unavailable }
    
    // Returns (uvIndex, cloudCover 0..1) using WeatherKit when available.
    func currentUV(for location: CLLocation) async throws -> (Double, Double) {
        if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
            let weather = try await WeatherService.shared.weather(for: location)
            let uvValue = Double(weather.currentWeather.uvIndex.value)
            // cloudCover is 0.0 ... 1.0; if unavailable, default to a modest value
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
    }
    
    // Convenience that also returns a human-readable category string.
    // Returns (uvIndex, cloudCover 0..1, description)
    func loadWeather(for location: CLLocation) async throws -> (Double, Double, String) {
        
        if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *) {
            
            let weather = try await WeatherService.shared.weather(for: location)
            let uv = weather.currentWeather.uvIndex
            let uvValue = Double(uv.value)
            let cloud = weather.currentWeather.cloudCover
            let description: String
            switch uv.category {
            case .low: description = "Low"
            case .moderate: description = "Moderate"
            case .high: description = "High"
            case .veryHigh: description = "Very High"
            case .extreme: description = "Extreme"
            @unknown default: description = "Unknown"
                
            }
            return (uvValue, cloud, description)
            
        } else {
            // Fallback stub for older OS versions
            let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
            let hour = Double(comps.hour ?? 12) + Double(comps.minute ?? 0) / 60.0
            let uvValue = max(0, 10.0 * sin((hour - 6.0) / 12.0 * .pi))
            let cloud = 0.3
            let description: String
            switch uvValue {
            case ..<3: description = "Low"
            case 3..<6: description = "Moderate"
            case 6..<8: description = "High"
            case 8..<11: description = "Very High"
            default: description = "Extreme"
            }
            return (uvValue, cloud, description)
        }
    }
}
