import Foundation

struct ExposureSession: Identifiable, Codable {
    let id: UUID
    var start: Date
    var end: Date?
    var spf: Int
    var clothing: ClothingLevel
    var skinType: FitzpatrickSkinType
    var estimatedIU: Double?

    init(start: Date, end: Date?, spf: Int, clothing: ClothingLevel, skinType: FitzpatrickSkinType, estimatedIU: Double? = nil) {
        self.id = UUID()
        self.start = start
        self.end = end
        self.spf = spf
        self.clothing = clothing
        self.skinType = skinType
        self.estimatedIU = estimatedIU
    }

    var durationMinutes: Int {
        let endDate = end ?? Date()
        return max(0, Int(endDate.timeIntervalSince(start) / 60.0))
    }
}
