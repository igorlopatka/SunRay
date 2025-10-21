import Foundation

actor PersistenceStore {
    private let settingsURL: URL
    private let historyURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        settingsURL = dir.appendingPathComponent("settings.json")
        historyURL = dir.appendingPathComponent("history.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func saveSettings(_ settings: UserSettings) async {
        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL, options: .atomic)
        } catch { }
    }

    func loadSettings() async -> UserSettings? {
        do {
            let data = try Data(contentsOf: settingsURL)
            return try decoder.decode(UserSettings.self, from: data)
        } catch {
            return nil
        }
    }

    func saveHistory(_ history: [ExposureSession]) async {
        do {
            let data = try encoder.encode(history)
            try data.write(to: historyURL, options: .atomic)
        } catch { }
    }

    func loadHistory() -> [ExposureSession] {
        do {
            let data = try Data(contentsOf: historyURL)
            return try decoder.decode([ExposureSession].self, from: data)
        } catch {
            return []
        }
    }
}
