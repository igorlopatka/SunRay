import Foundation
import Combine

final class SunrayDebugSettings: ObservableObject {
    static let shared = SunrayDebugSettings()

    @Published var intensity: Float = 1.0
    @Published var beamWidth: Float = 0.5
    @Published var beamCount: Float = 12.0
    @Published var hue: Float = 0.08 // warm tint
    @Published var isVisible: Bool = true

    private init() {}
}
