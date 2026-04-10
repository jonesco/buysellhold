import Foundation
import SwiftData

@Model
final class UserPreferences {
    var id: UUID
    var defaultHighPercentage: Double
    var defaultLowPercentage: Double

    init(defaultHighPercentage: Double = 10.0, defaultLowPercentage: Double = -10.0) {
        self.id = UUID()
        self.defaultHighPercentage = defaultHighPercentage
        self.defaultLowPercentage = defaultLowPercentage
    }
}
