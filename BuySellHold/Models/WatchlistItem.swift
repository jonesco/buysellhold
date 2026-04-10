import Foundation
import SwiftData

@Model
final class WatchlistItem {
    var id: UUID
    var stockSymbol: String
    var companyName: String
    var currentPrice: Double
    var lowerThreshold: Double
    var upperThreshold: Double
    var initialPrice: Double
    var targetPrice: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        stockSymbol: String,
        companyName: String = "",
        currentPrice: Double,
        lowerThreshold: Double,
        upperThreshold: Double,
        initialPrice: Double,
        targetPrice: Double
    ) {
        self.id = UUID()
        self.stockSymbol = stockSymbol
        self.companyName = companyName
        self.currentPrice = currentPrice
        self.lowerThreshold = lowerThreshold
        self.upperThreshold = upperThreshold
        self.initialPrice = initialPrice
        self.targetPrice = targetPrice
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
