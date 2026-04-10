import SwiftUI
import SwiftData

struct AddStockSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: WatchlistViewModel
    let existingSymbols: [String]

    @State private var ticker = ""
    @State private var currentPrice: Double?
    @State private var companyName = ""
    @State private var targetPriceText = ""
    @State private var lowPriceText = ""
    @State private var highPriceText = ""
    @State private var lowPercentageText = ""
    @State private var lowPercentage: Double?
    @State private var highPercentage: Double?
    @State private var error = ""
    @State private var isLoading = false
    @State private var selectedDetent: PresentationDetent = .large
    @FocusState private var isTickerFieldFocused: Bool

    private var targetPrice: Double? { Double(targetPriceText) }
    private var lowPrice: Double? { Double(lowPriceText) }
    private var highPrice: Double? { Double(highPriceText) }

    private var addStockFormContent: some View {
        VStack(spacing: 16) {
            if let price = currentPrice {
                        // Stock info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(companyName) (\(ticker))")
                                .font(.custom("WorkSans-SemiBold", size: 18))
                                .foregroundColor(.white)
                            Text("Current price: $\(price, specifier: "%.2f")")
                                .font(.custom("WorkSans-Regular", size: 14))
                                .foregroundColor(Color.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)

                        // Target Price
                        InputField(label: "Target Price", text: $targetPriceText, placeholder: "Enter target price") {
                            recalcPricesFromPercentages()
                        }

                        // Low Price
                        HStack(spacing: 8) {
                            InputField(label: "Low Price", text: $lowPriceText, placeholder: "Enter low price") {
                                if let low = lowPrice, let target = targetPrice, target > 0 {
                                    let computedLow = ((low - target) / target) * 100
                                    lowPercentage = computedLow
                                    lowPercentageText = String(format: "%.1f", computedLow)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("%")
                                    .font(.custom("WorkSans-Medium", size: 13))
                                    .foregroundColor(Color.gray)
                                ZStack(alignment: .leading) {
                                    if lowPercentageText.isEmpty {
                                        Text("%")
                                            .font(.custom("WorkSans-Regular", size: 15))
                                            .foregroundColor(AppColors.holdGray)
                                    }
                                    TextField("", text: $lowPercentageText)
                                    .onChange(of: lowPercentageText) { _, newValue in
                                        let normalized = normalizedLowPercentageText(newValue)
                                        if normalized != newValue {
                                            lowPercentageText = normalized
                                            return
                                        }

                                        guard let val = parsedLowPercentage(from: normalized) else {
                                            lowPercentage = nil
                                            return
                                        }

                                        lowPercentage = val
                                        if let target = targetPrice, target > 0 {
                                            let price = target * (1 + val / 100)
                                            lowPriceText = String(format: "%.2f", price)
                                        }
                                    }
                                    .numbersAndPunctuationKeyboard()
                                    .font(.custom("WorkSans-Regular", size: 15))
                                    .foregroundColor(.white)
                                }
                                .padding(10)
                                .background(AppColors.inputDark)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))
                            }
                            .frame(width: 80)
                        }

                        // High Price
                        HStack(spacing: 8) {
                            InputField(label: "High Price", text: $highPriceText, placeholder: "Enter high price") {
                                if let high = highPrice, let target = targetPrice, target > 0 {
                                    highPercentage = ((high - target) / target) * 100
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("%")
                                    .font(.custom("WorkSans-Medium", size: 13))
                                    .foregroundColor(Color.gray)
                                ZStack(alignment: .leading) {
                                    if highPercentage == nil {
                                        Text("%")
                                            .font(.custom("WorkSans-Regular", size: 15))
                                            .foregroundColor(AppColors.holdGray)
                                    }
                                    TextField("", text: Binding(
                                        get: { highPercentage != nil ? String(format: "%.1f", highPercentage!) : "" },
                                        set: { newValue in
                                            if let val = Double(newValue), let target = targetPrice, target > 0 {
                                                highPercentage = val
                                                let price = target * (1 + val / 100)
                                                highPriceText = String(format: "%.2f", price)
                                            }
                                        }
                                    ))
                                    .decimalPadKeyboard()
                                    .font(.custom("WorkSans-Regular", size: 15))
                                    .foregroundColor(.white)
                                }
                                .padding(10)
                                .background(AppColors.inputDark)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))
                            }
                            .frame(width: 80)
                        }
                    } else {
                        // Symbol input
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stock Symbol")
                                .font(.custom("WorkSans-Medium", size: 13))
                                .foregroundColor(Color.gray)
                            ZStack(alignment: .leading) {
                                if ticker.isEmpty {
                                    Text("Enter stock symbol (e.g., AAPL)")
                                        .font(.custom("WorkSans-Regular", size: 15))
                                        .foregroundColor(AppColors.holdGray)
                                }
                                TextField("", text: $ticker)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    #endif
                                    .focused($isTickerFieldFocused)
                                    .font(.custom("WorkSans-Regular", size: 15))
                                    .foregroundColor(Color.white)
                                    .onSubmit { Task { await fetchPrice() } }
                            }
                            .padding(10)
                            .background(AppColors.inputDark)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))
                        }
                    }

                    if !error.isEmpty {
                        Text(error)
                            .font(.custom("WorkSans-Regular", size: 13))
                            .foregroundColor(.red)
                    }

                    // Buttons
                    HStack {
                        Spacer()
                        Button("Cancel") { dismiss() }
                            .font(.custom("WorkSans-Regular", size: 15))
                            .foregroundColor(Color.gray)
                            .padding(.trailing, 16)

                        if currentPrice == nil {
                            Button(action: { Task { await fetchPrice() } }) {
                                Text(isLoading ? "Loading..." : "Get Price")
                                    .font(.custom("WorkSans-Medium", size: 15))
                                    .foregroundColor(AppColors.foreground)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(ticker.isEmpty || isLoading ? Color.white.opacity(0.5) : Color.white)
                                    .cornerRadius(8)
                            }
                            .disabled(ticker.isEmpty || isLoading)
                        } else {
                            Button(action: addStock) {
                                Text("Add Stock")
                                    .font(.custom("WorkSans-Medium", size: 15))
                                    .foregroundColor(AppColors.foreground)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(canAdd ? Color.white : Color.white.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            .disabled(!canAdd)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 92)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                addStockFormContent
            }
            .background(AppColors.cardDark)
            .navigationTitle("Add Stock")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.cardDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.white.opacity(0.9))
                            .fontWeight(.medium)
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.white.opacity(0.9))
                            .fontWeight(.medium)
                    }
                }
                #endif
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        #endif
        .onAppear {
            guard currentPrice == nil else { return }
            selectedDetent = .large
            DispatchQueue.main.async {
                isTickerFieldFocused = true
            }
        }
        .onChange(of: currentPrice) { _, newValue in
            if newValue == nil {
                selectedDetent = .large
                DispatchQueue.main.async {
                    isTickerFieldFocused = true
                }
            } else {
                isTickerFieldFocused = false
            }
        }
    }

    private var canAdd: Bool {
        guard let target = targetPrice, let low = lowPrice, let high = highPrice else { return false }
        return target > 0 && low > 0 && high > 0 && low < high
    }

    private func fetchPrice() async {
        let symbol = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !symbol.isEmpty else {
            error = "Please enter a ticker symbol"
            return
        }

        if existingSymbols.contains(symbol) {
            error = "This stock is already being tracked"
            return
        }

        isLoading = true
        error = ""

        do {
            let quote = try await FinnhubService.shared.fetchQuote(symbol: symbol)
            await MainActor.run {
                ticker = symbol
                currentPrice = quote.price
                companyName = quote.companyName

                let prefs = viewModel.getPreferences(context: modelContext)
                let defaultLow = prefs.defaultLowPercentage
                let defaultHigh = prefs.defaultHighPercentage

                targetPriceText = String(format: "%.2f", quote.price)
                let low = quote.price * (1 + defaultLow / 100)
                let high = quote.price * (1 + defaultHigh / 100)
                lowPriceText = String(format: "%.2f", low)
                highPriceText = String(format: "%.2f", high)
                lowPercentage = defaultLow
                lowPercentageText = String(format: "%.1f", defaultLow)
                highPercentage = defaultHigh
                isLoading = false
            }
        } catch let finnhubError as FinnhubError {
            await MainActor.run {
                self.error = finnhubError.localizedDescription ?? "Failed to fetch stock data."
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch stock data. Please try again."
                isLoading = false
            }
        }
    }

    private func recalcPercentagesFromPrices() {
        guard let target = targetPrice, target > 0 else { return }
        if let low = lowPrice {
            let computedLow = ((low - target) / target) * 100
            lowPercentage = computedLow
            lowPercentageText = String(format: "%.1f", computedLow)
        }
        if let high = highPrice {
            highPercentage = ((high - target) / target) * 100
        }
    }

    private func recalcPricesFromPercentages() {
        guard let target = targetPrice, target > 0 else { return }
        if let lowPercentage {
            let low = target * (1 + lowPercentage / 100)
            lowPriceText = String(format: "%.2f", low)
        }
        if let highPercentage {
            let high = target * (1 + highPercentage / 100)
            highPriceText = String(format: "%.2f", high)
        }
    }

    private func addStock() {
        guard let price = currentPrice,
              let target = targetPrice,
              let low = lowPrice,
              let high = highPrice,
              low < high else {
            error = "Please set all required fields correctly"
            return
        }

        viewModel.addStock(
            symbol: ticker,
            companyName: companyName,
            currentPrice: price,
            lowerThreshold: low,
            upperThreshold: high,
            initialPrice: price,
            targetPrice: target,
            context: modelContext
        )
        dismiss()
    }

    private func normalizedLowPercentageText(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let withoutAnyMinus = trimmed.replacingOccurrences(of: "-", with: "")
        if withoutAnyMinus.isEmpty { return "-" }

        return "-\(withoutAnyMinus)"
    }

    private func parsedLowPercentage(from normalized: String) -> Double? {
        guard !normalized.isEmpty, normalized != "-", let value = Double(normalized) else {
            return nil
        }
        return -abs(value)
    }
}

private struct InputField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var onCommit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("WorkSans-Medium", size: 13))
                .foregroundColor(Color.gray)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.custom("WorkSans-Regular", size: 15))
                        .foregroundColor(AppColors.holdGray)
                }
                TextField("", text: $text, onCommit: onCommit)
                    .decimalPadKeyboard()
                    .font(.custom("WorkSans-Regular", size: 15))
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(AppColors.inputDark)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))
        }
    }
}
