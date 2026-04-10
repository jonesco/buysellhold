import Foundation

struct StockQuote {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int
    let companyName: String
}

actor FinnhubService {
    static let shared = FinnhubService()

    private let baseURL = "https://finnhub.io/api/v1"
    private var apiKey: String {
        KeychainHelper.get(account: "finnhubApiKey") ?? ""
    }

    func validateApiKey(_ key: String) async -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: "\(baseURL)/quote?symbol=AAPL&token=\(key)") else {
            return false
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let price = json["c"] as? Double, price > 0 else {
                return false
            }
            return true
        } catch {
            return false
        }
    }

    func fetchQuote(symbol: String) async throws -> StockQuote {
        guard !apiKey.isEmpty else {
            throw FinnhubError.noApiKey
        }
        // Fetch quote
        guard let quoteURL = URL(string: "\(baseURL)/quote?symbol=\(symbol)&token=\(apiKey)") else {
            throw FinnhubError.invalidURL
        }

        let (quoteData, quoteResponse) = try await URLSession.shared.data(from: quoteURL)

        guard let httpResponse = quoteResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FinnhubError.requestFailed
        }

        guard let quoteJSON = try JSONSerialization.jsonObject(with: quoteData) as? [String: Any],
              let currentPrice = quoteJSON["c"] as? Double,
              currentPrice > 0 else {
            throw FinnhubError.noData
        }

        let change = quoteJSON["d"] as? Double ?? 0
        let changePercent = quoteJSON["dp"] as? Double ?? 0
        let volume = quoteJSON["v"] as? Int ?? 0

        // Fetch company name
        let companyName = await fetchCompanyName(symbol: symbol)

        return StockQuote(
            symbol: symbol,
            price: currentPrice,
            change: change,
            changePercent: changePercent,
            volume: volume,
            companyName: companyName
        )
    }

    private func fetchCompanyName(symbol: String) async -> String {
        guard let url = URL(string: "\(baseURL)/stock/profile2?symbol=\(symbol)&token=\(apiKey)") else {
            return symbol
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = json["name"] as? String, !name.isEmpty {
                return name
            }
        } catch {
            // Fallback to symbol
        }
        return symbol
    }
}

enum FinnhubError: LocalizedError {
    case noApiKey
    case invalidURL
    case requestFailed
    case noData

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "No Finnhub API key set. Go to Settings → API Keys to add yours."
        case .invalidURL: return "Invalid URL"
        case .requestFailed: return "Request failed"
        case .noData: return "No data found for this symbol"
        }
    }
}
