import Foundation
import os

actor PersistenceStore {
    // Persisted alongside an active session so that a force-quit or crash
    // can be recovered on next launch. UV and cloud values are snapshotted
    // at session start so the final IU estimate uses the correct conditions.
    struct ActiveSessionRecord: Codable {
        var session: ExposureSession
        var startUV: Double?
        var startCloud: Double?
    }

    private let settingsURL: URL
    private let historyURL: URL
    private let activeSessionURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        settingsURL = dir.appendingPathComponent("settings.json")
        historyURL = dir.appendingPathComponent("history.json")
        activeSessionURL = dir.appendingPathComponent("active_session.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func saveSettings(_ settings: UserSettings) throws {
        let data = try encoder.encode(settings)
        try data.write(to: settingsURL, options: .atomic)
    }

    func loadSettings() -> UserSettings? {
        do {
            let data = try Data(contentsOf: settingsURL)
            return try decoder.decode(UserSettings.self, from: data)
        } catch {
            SRLog("PersistenceStore.loadSettings error reading from \(settingsURL): \(error)", level: .error)
            return nil
        }
    }

    func saveHistory(_ history: [ExposureSession]) throws {
        let data = try encoder.encode(history)
        try data.write(to: historyURL, options: .atomic)
    }

    func loadHistory() -> [ExposureSession] {
        do {
            let data = try Data(contentsOf: historyURL)
            return try decoder.decode([ExposureSession].self, from: data)
        } catch {
            SRLog("PersistenceStore.loadHistory error reading from \(historyURL): \(error)", level: .error)
            return []
        }
    }

    // Pass nil to clear the active-session file (call after a session ends normally).
    func saveActiveSession(_ record: ActiveSessionRecord?) throws {
        if let record {
            let data = try encoder.encode(record)
            try data.write(to: activeSessionURL, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: activeSessionURL)
        }
    }

    func loadActiveSession() -> ActiveSessionRecord? {
        guard let data = try? Data(contentsOf: activeSessionURL) else { return nil }
        do {
            return try decoder.decode(ActiveSessionRecord.self, from: data)
        } catch {
            SRLog("PersistenceStore.loadActiveSession decode error: \(error)", level: .error)
            try? FileManager.default.removeItem(at: activeSessionURL)
            return nil
        }
    }
}
