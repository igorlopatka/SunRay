import Foundation
import OSLog

extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.sunray.app", category: "SunRay")
}

func SRLog(_ message: String, level: OSLogType = .default) {
    switch level {
    case .debug: Logger.app.debug("\(message)")
    case .error: Logger.app.error("\(message)")
    case .info: Logger.app.info("\(message)")
    default: Logger.app.log("\(message)")
    }
}
