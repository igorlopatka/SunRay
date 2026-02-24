import Foundation
import SwiftUI
import Combine
import CoreLocation
import os

@MainActor
final class AppState: ObservableObject {
    // Services
    let locationService = LocationService()
    let uvService = UVService()
    let hkService: HealthKitProviding
    let persistence = PersistenceStore()

    // User settings
    @Published var settings = UserSettings()

    // Live data
    @Published var currentUVIndex: Double? = nil
    @Published var cloudCover: Double? = nil

    // Sessions
    @Published private(set) var activeSession: ExposureSession? = nil
    @Published private(set) var history: [ExposureSession] = []

    // HealthKit
    @Published private(set) var healthKitAuthorized: Bool = false

    // Alerts
    struct UIAlert: Identifiable { let id = UUID(); let title: String; let message: String }
    @Published var activeAlert: UIAlert? = nil

    // Daily synthesis accumulation (in-app only)
    @Published var todaySynthesizedIU: Double = 0

    // UV snapshot captured when a session starts
    private var sessionStartUV: Double?
    private var sessionStartCloudCover: Double?

    var isSessionActive: Bool { activeSession != nil }

    var allSessions: [ExposureSession] { history }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var locationSummary: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if let placemark = locationService.placemark {
                return [placemark.locality, placemark.country].compactMap { $0 }.joined(separator: ", ")
            } else if let loc = locationService.location {
                return "Lat \(String(format: "%.3f", loc.coordinate.latitude)), Lon \(String(format: "%.3f", loc.coordinate.longitude))"
            } else {
                return "Locating…"
            }
        case .notDetermined:
            return "Location permission needed"
        default:
            return "Location unavailable"
        }
    }

    var uvIndexString: String {
        guard let uv = currentUVIndex else { return "--" }
        return String(format: "%.1f", uv)
    }

    var uvColor: Color {
        guard let uv = currentUVIndex else { return .secondary }
        switch uv {
        case ..<3:  return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default:    return .purple // Extreme (11+)
        }
    }

    var cloudCoverString: String {
        guard let cc = cloudCover else { return "—%" }
        return "\(Int(cc * 100))%"
    }

    var uvAdvisory: String {
        guard let uv = currentUVIndex else { return "—" }
        if uv < 3  { return "Low — UVB too weak for significant synthesis." }
        if uv < 6  { return "Moderate — short exposure effective." }
        if uv < 8  { return "High — limit exposure, apply SPF." }
        if uv < 11 { return "Very high — minimize direct sun." }
        return "Extreme — avoid sun exposure."
    }

    // Estimated time-to-burn for unprotected skin at the current UV index.
    // Does not account for SPF — multiply by SPF factor for protected estimate.
    var burnTimeString: String? {
        guard let uv = currentUVIndex,
              let mins = VitaminDModel.burnTimeMinutes(uvIndex: uv, skinType: settings.skinType),
              mins.isFinite else { return nil }
        let m = Int(mins.rounded())
        if m >= 60 {
            let rem = m % 60
            return rem == 0 ? "\(m / 60)h" : "\(m / 60)h \(rem)m"
        }
        return "\(m) min"
    }

    // Estimated IU accumulated so far in the active session (updated by caller via timer).
    var liveSessionIU: Double {
        guard let session = activeSession else { return 0 }
        let elapsed = Date().timeIntervalSince(session.start) / 60.0
        guard elapsed > 0 else { return 0 }
        let uv = sessionStartUV ?? currentUVIndex ?? 0
        let cc = sessionStartCloudCover ?? cloudCover ?? 0
        return VitaminDModel.estimateSynthesizedIU(
            uvIndex: uv, minutes: elapsed, cloudCover: cc,
            skinType: session.skinType, spf: session.spf,
            exposedPercent: session.clothing.exposedPercent, age: settings.age
        )
    }

    struct ExposureRecommendation {
        let durationMinutes: Int
    }

    // Returns a recommendation only when UV ≥ 3 (below this threshold UVB is too
    // weak for meaningful vitamin D synthesis regardless of exposure duration).
    // Caps at 240 min to avoid surfacing unrealistic estimates.
    var exposureRecommendation: ExposureRecommendation? {
        guard let uv = currentUVIndex, uv >= 3 else { return nil }
        let minutes = VitaminDModel.recommendedMinutesToGoal(
            currentUV: uv,
            cloudCover: cloudCover ?? 0,
            settings: settings,
            alreadySynthesizedIU: todaySynthesizedIU
        )
        guard minutes > 0, minutes.isFinite, minutes <= 240 else { return nil }
        return .init(durationMinutes: Int(minutes.rounded()))
    }

    init() {
        #if canImport(HealthKit)
        self.hkService = HealthKitService()
        #else
        self.hkService = NoOpHealthKitService()
        #endif
    }

    static let preview: AppState = {
        let s = AppState()
        s.currentUVIndex = 5.4
        s.cloudCover = 0.2
        s.settings = UserSettings()
        s.todaySynthesizedIU = 400
        return s
    }()

    private func todayIUFromHistory() -> Double {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return history
            .filter { $0.start >= startOfToday }
            .compactMap(\.estimatedIU)
            .reduce(0, +)
    }

    func bootstrap() async {
        if let saved = await persistence.loadSettings() {
            settings = saved
        }
        history = await persistence.loadHistory()
        todaySynthesizedIU = todayIUFromHistory()

        do {
            try await locationService.requestAuthorization()
        } catch {
            activeAlert = .init(title: "Location", message: "Location permission is required for UV estimation.")
        }

        // HealthKit authorization (may be false on unsupported devices)
        do {
            healthKitAuthorized = try await hkService.requestAuthorization()
        } catch {
            SRLog("AppState: HealthKit authorization failed: \(error)", level: .error)
            healthKitAuthorized = false
        }

        await refreshEnvironmentalData()
        locationService.onLocationUpdate = { [weak self] _ in
            Task { await self?.refreshEnvironmentalData() }
        }
    }

    func refreshEnvironmentalData() async {
        guard let loc = locationService.location else {
            SRLog("refreshEnvironmentalData: location is nil", level: .error)
            return
        }
        do {
            let (uv, cc) = try await uvService.currentUV(for: loc)
            SRLog("refreshEnvironmentalData: uv=\(uv), cloud=\(cc)", level: .info)
            currentUVIndex = uv
            cloudCover = cc
        } catch {
            SRLog("refreshEnvironmentalData failed: \(error)", level: .error)
            currentUVIndex = nil
            cloudCover = nil
            activeAlert = .init(title: "UV Data Unavailable", message: "Could not fetch current UV index. Check your connection and try again.")
        }
    }

    func saveSettings() async {
        do {
            try await persistence.saveSettings(settings)
        } catch {
            SRLog("AppState: saveSettings failed: \(error)", level: .error)
            activeAlert = .init(title: "Save Failed", message: "Your settings could not be saved. Changes may be lost when the app restarts.")
        }
    }

    func startSession(spf: Int, clothing: ClothingLevel) {
        guard activeSession == nil else { return }
        sessionStartUV = currentUVIndex
        sessionStartCloudCover = cloudCover
        let session = ExposureSession(start: Date(), end: nil, spf: spf, clothing: clothing, skinType: settings.skinType)
        activeSession = session
    }

    func updateActiveSession(spf: Int, clothing: ClothingLevel) {
        guard var session = activeSession else { return }
        session.spf = spf
        session.clothing = clothing
        activeSession = session
    }

    func stopSessionAndSave() async {
        guard var session = activeSession else { return }
        session.end = Date()

        let uv = sessionStartUV ?? currentUVIndex ?? 0
        let cc = sessionStartCloudCover ?? cloudCover ?? 0
        let minutes = max(0, session.durationMinutes)
        let iu = VitaminDModel.estimateSynthesizedIU(
            uvIndex: uv,
            minutes: Double(minutes),
            cloudCover: cc,
            skinType: session.skinType,
            spf: session.spf,
            exposedPercent: session.clothing.exposedPercent,
            age: settings.age
        )
        session.estimatedIU = iu

        // Save to HealthKit (ignored on unsupported platforms)
        do {
            try await hkService.saveUVExposure(durationMinutes: minutes, uvIndex: uv, location: locationService.location)
        } catch {
            SRLog("AppState: HealthKit saveUVExposure failed: \(error)", level: .error)
        }

        do {
            try await hkService.saveVitaminD(estimatedIU: iu, start: session.start, end: session.end ?? Date())
        } catch {
            SRLog("AppState: HealthKit saveVitaminD failed: \(error)", level: .error)
        }

        todaySynthesizedIU += iu
        history.insert(session, at: 0)
        do {
            try await persistence.saveHistory(history)
        } catch {
            SRLog("AppState: saveHistory failed: \(error)", level: .error)
            activeAlert = .init(title: "Save Failed", message: "Your session was recorded but could not be saved to disk. It may be lost when the app restarts.")
        }

        activeSession = nil
        sessionStartUV = nil
        sessionStartCloudCover = nil
    }

    func deleteSession(_ session: ExposureSession) {
        history.removeAll { $0.id == session.id }
        todaySynthesizedIU = todayIUFromHistory()
        Task {
            do {
                try await persistence.saveHistory(history)
            } catch {
                SRLog("AppState: deleteSession saveHistory failed: \(error)", level: .error)
                activeAlert = .init(title: "Delete Failed", message: "The session could not be deleted from disk.")
            }
        }
    }
}

