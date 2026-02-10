import Foundation
import os

actor PersistenceStore {
    private let settingsURL: URL
    private let historyURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        settingsURL = dir.appendingPathComponent("settings.json")
        historyURL = dir.appendingPathComponent("history.json")
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
}
