import Foundation
import SwiftData
import SwiftUI

enum SortOption: String, CaseIterable {
    case alphabetical = "alphabetical"
    case changeFromTargetPercent = "changeFromTargetPercent"
    case changeFromTargetDollar = "changeFromTargetDollar"

    var displayName: String {
        switch self {
        case .alphabetical: return "Alphabetical"
        case .changeFromTargetPercent: return "Change from Target (%)"
        case .changeFromTargetDollar: return "Change from Target ($)"
        }
    }
}

@Observable
final class WatchlistViewModel {
    var livePrices: [UUID: Double] = [:]
    var searchQuery: String = ""
    var sortOption: SortOption = .alphabetical
    var isLoading: Bool = false
    var showLoader: Bool = false
    var showContent: Bool = false
    var showAddSheet: Bool = false
    var showSettingsSheet: Bool = false
    var showSortMenu: Bool = false

    private var loaderStartTime: Date?
    private let minimumLoaderDuration: TimeInterval = 3.0

    init() {
        // Load saved sort preference
        if let saved = UserDefaults.standard.string(forKey: "sortPreference"),
           let option = SortOption(rawValue: saved) {
            sortOption = option
        }
    }

    func setSortOption(_ option: SortOption) {
        sortOption = option
        UserDefaults.standard.set(option.rawValue, forKey: "sortPreference")
    }

    func filteredAndSorted(_ items: [WatchlistItem]) -> [WatchlistItem] {
        var filtered = items

        // Filter by search query
        if !searchQuery.isEmpty {
            let query = searchQuery.uppercased()
            filtered = filtered.filter { $0.stockSymbol.uppercased().hasPrefix(query) }
        }

        // Sort
        switch sortOption {
        case .alphabetical:
            filtered.sort { $0.stockSymbol < $1.stockSymbol }
        case .changeFromTargetPercent:
            filtered.sort { a, b in
                let aPrice = livePrices[a.id] ?? a.currentPrice
                let bPrice = livePrices[b.id] ?? b.currentPrice
                let aPercent = a.targetPrice > 0 ? ((aPrice - a.targetPrice) / a.targetPrice) * 100 : 0
                let bPercent = b.targetPrice > 0 ? ((bPrice - b.targetPrice) / b.targetPrice) * 100 : 0
                return bPercent > aPercent // Highest first
            }
        case .changeFromTargetDollar:
            filtered.sort { a, b in
                let aPrice = livePrices[a.id] ?? a.currentPrice
                let bPrice = livePrices[b.id] ?? b.currentPrice
                let aDollar = aPrice - a.targetPrice
                let bDollar = bPrice - b.targetPrice
                return bDollar > aDollar // Highest first
            }
        }

        return filtered
    }

    func startLoading() {
        showLoader = true
        showContent = false
        loaderStartTime = Date()
    }

    func finishLoading() {
        guard let startTime = loaderStartTime else {
            showLoader = false
            showContent = true
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed >= minimumLoaderDuration {
            showLoader = false
            showContent = true
            loaderStartTime = nil
        } else {
            let remaining = minimumLoaderDuration - elapsed
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in
                self?.showLoader = false
                self?.showContent = true
                self?.loaderStartTime = nil
            }
        }
    }

    func fetchLivePrices(for items: [WatchlistItem]) async {
        await withTaskGroup(of: (UUID, Double?).self) { group in
            for item in items {
                group.addTask {
                    do {
                        let quote = try await FinnhubService.shared.fetchQuote(symbol: item.stockSymbol)
                        return (item.id, quote.price)
                    } catch {
                        return (item.id, nil)
                    }
                }
            }

            for await (id, price) in group {
                if let price {
                    await MainActor.run {
                        self.livePrices[id] = price
                    }
                }
            }
        }
    }

    func addStock(
        symbol: String,
        companyName: String,
        currentPrice: Double,
        lowerThreshold: Double,
        upperThreshold: Double,
        initialPrice: Double,
        targetPrice: Double,
        context: ModelContext
    ) {
        let item = WatchlistItem(
            stockSymbol: symbol,
            companyName: companyName,
            currentPrice: currentPrice,
            lowerThreshold: lowerThreshold,
            upperThreshold: upperThreshold,
            initialPrice: initialPrice,
            targetPrice: targetPrice
        )
        context.insert(item)
        try? context.save()
    }

    func updateStock(
        item: WatchlistItem,
        lowerThreshold: Double,
        upperThreshold: Double,
        targetPrice: Double,
        context: ModelContext
    ) {
        item.lowerThreshold = lowerThreshold
        item.upperThreshold = upperThreshold
        item.targetPrice = targetPrice
        item.updatedAt = Date()
        try? context.save()
    }

    func deleteStock(item: WatchlistItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
        livePrices.removeValue(forKey: item.id)
    }

    func currentPrice(for item: WatchlistItem) -> Double {
        livePrices[item.id] ?? item.currentPrice
    }

    func priceChange(for item: WatchlistItem) -> (dollar: Double, percent: Double) {
        let price = currentPrice(for: item)
        let target = item.targetPrice
        let dollarChange = price - target
        let percentChange = target > 0 ? (dollarChange / target) * 100 : 0
        return (dollarChange, percentChange)
    }

    func lowPercentage(for item: WatchlistItem) -> Double {
        let target = item.targetPrice
        return target > 0 ? ((item.lowerThreshold - target) / target) * 100 : 0
    }

    func highPercentage(for item: WatchlistItem) -> Double {
        let target = item.targetPrice
        return target > 0 ? ((item.upperThreshold - target) / target) * 100 : 0
    }

    func getPreferences(context: ModelContext) -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let prefs = UserPreferences()
        context.insert(prefs)
        try? context.save()
        return prefs
    }
}
