import Foundation
import CoreLocation

struct SunPositionService {
    func solarElevation(for location: CLLocation, at date: Date) async -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let time = Double(hour) + Double(minutes) / 60.0

        let lat = location.coordinate.latitude
        let day = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 172)
        let decl = -23.44 * cos((360 / 365.0) * (day + 10) * .pi / 180)
        let maxElevation = max(0, 90 - abs(lat - decl))
        let diurnal = max(0, sin((time - 6) / 14.0 * .pi))
        return maxElevation * diurnal
    }
}
