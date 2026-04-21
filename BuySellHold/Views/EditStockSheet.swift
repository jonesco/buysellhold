import SwiftUI
import SwiftData

struct EditStockSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: WatchlistItem
    @Bindable var viewModel: WatchlistViewModel

    @State private var targetPriceText: String
    @State private var lowPriceText: String
    @State private var highPriceText: String
    @State private var lowPercentageText: String
    @State private var lowPercentage: Double?
    @State private var highPercentage: Double?
    @State private var resetFlash = false
    @State private var showResetNotice = false

    init(item: WatchlistItem, viewModel: WatchlistViewModel) {
        self.item = item
        self.viewModel = viewModel

        let target = item.targetPrice
        let low = item.lowerThreshold
        let high = item.upperThreshold

        _targetPriceText = State(initialValue: String(format: "%.2f", target))
        _lowPriceText = State(initialValue: String(format: "%.2f", low))
        _highPriceText = State(initialValue: String(format: "%.2f", high))
        let initialLowPercentage = target > 0 ? ((low - target) / target) * 100 : nil
        _lowPercentageText = State(initialValue: initialLowPercentage.map { String(format: "%.1f", $0) } ?? "")
        _lowPercentage = State(initialValue: initialLowPercentage)
        _highPercentage = State(initialValue: target > 0 ? ((high - target) / target) * 100 : nil)
    }

    private var targetPrice: Double? { Double(targetPriceText) }
    private var lowPrice: Double? { Double(lowPriceText) }
    private var highPrice: Double? { Double(highPriceText) }
    private var price: Double { viewModel.currentPrice(for: item) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Stock info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.companyName.isEmpty ? item.stockSymbol : "\(item.companyName) (\(item.stockSymbol))")
                            .font(.custom("WorkSans-SemiBold", size: 18))
                            .foregroundColor(.white)
                        Text("Current price: $\(price, specifier: "%.2f")")
                            .font(.custom("WorkSans-Regular", size: 14))
                            .foregroundStyle(Color.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)

                    // Target Price
                    DarkInputField(label: "Target Price", text: $targetPriceText, highlighted: resetFlash, onChange: recalcPricesFromPercentages) {
                        recalcPricesFromPercentages()
                    }

                    // Low Price
                    HStack(spacing: 8) {
                        DarkInputField(label: "Low Price", text: $lowPriceText, highlighted: resetFlash, onChange: {
                            if let low = lowPrice, let target = targetPrice, target > 0 {
                                let computedLow = ((low - target) / target) * 100
                                lowPercentage = computedLow
                                lowPercentageText = String(format: "%.1f", computedLow)
                            }
                        }) {
                            if let low = lowPrice, let target = targetPrice, target > 0 {
                                let computedLow = ((low - target) / target) * 100
                                lowPercentage = computedLow
                                lowPercentageText = String(format: "%.1f", computedLow)
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("%")
                                .font(.custom("WorkSans-Medium", size: 13))
                                .foregroundStyle(Color.gray)
                            ZStack(alignment: .leading) {
                                if lowPercentageText.isEmpty {
                                    Text("%")
                                        .font(.custom("WorkSans-Regular", size: 15))
                                        .foregroundStyle(AppColors.holdGray)
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
                                        let p = target * (1 + val / 100)
                                        lowPriceText = String(format: "%.2f", p)
                                    }
                                }
                                .numbersAndPunctuationKeyboard()
                                .font(.custom("WorkSans-Regular", size: 15))
                                .foregroundColor(.white)
                            }
                            .padding(10)
                            .background(AppColors.inputDark)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(resetFlash ? AppColors.buyGreen : AppColors.borderDark, lineWidth: resetFlash ? 2 : 1))
                        }
                        .frame(width: 80)
                    }

                    // High Price
                    HStack(spacing: 8) {
                        DarkInputField(label: "High Price", text: $highPriceText, highlighted: resetFlash, onChange: {
                            if let high = highPrice, let target = targetPrice, target > 0 {
                                highPercentage = ((high - target) / target) * 100
                            }
                        }) {
                            if let high = highPrice, let target = targetPrice, target > 0 {
                                highPercentage = ((high - target) / target) * 100
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("%")
                                .font(.custom("WorkSans-Medium", size: 13))
                                .foregroundStyle(Color.gray)
                            ZStack(alignment: .leading) {
                                if highPercentage == nil {
                                    Text("%")
                                        .font(.custom("WorkSans-Regular", size: 15))
                                        .foregroundStyle(AppColors.holdGray)
                                }
                                TextField("", text: Binding(
                                    get: { highPercentage != nil ? String(format: "%.1f", highPercentage!) : "" },
                                    set: { newValue in
                                        if let val = Double(newValue), let target = targetPrice, target > 0 {
                                            highPercentage = val
                                            let p = target * (1 + val / 100)
                                            highPriceText = String(format: "%.2f", p)
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
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(resetFlash ? AppColors.buyGreen : AppColors.borderDark, lineWidth: resetFlash ? 2 : 1))
                        }
                        .frame(width: 80)
                    }

                    // Reset notice / Buttons
                    if showResetNotice {
                        Text("Prices reset to defaults")
                            .font(.custom("WorkSans-Regular", size: 13))
                            .foregroundStyle(AppColors.buyGreen)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .transition(.opacity)
                    } else {
                        HStack {
                            // Reset button
                            Button(action: resetToDefaults) {
                                Text("Reset")
                                    .font(.custom("WorkSans-Regular", size: 15))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                            }

                            Spacer()

                            Button("Cancel") { dismiss() }
                                .font(.custom("WorkSans-Regular", size: 15))
                                .foregroundColor(Color.gray)
                                .padding(.trailing, 16)

                            Button(action: saveChanges) {
                                Text("Save Changes")
                                    .font(.custom("WorkSans-Medium", size: 15))
                                    .foregroundColor(AppColors.foreground)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 8)
                        .transition(.opacity)
                    }
                }
                .padding(20)
            }
            .background(AppColors.cardDark)
            .navigationTitle("Edit Stock")
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
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

    private func resetToDefaults() {
        let prefs = viewModel.getPreferences(context: modelContext)
        let newTarget = price
        targetPriceText = String(format: "%.2f", newTarget)

        let high = newTarget * (1 + prefs.defaultHighPercentage / 100)
        let low = newTarget * (1 + prefs.defaultLowPercentage / 100)

        highPriceText = String(format: "%.2f", high)
        lowPriceText = String(format: "%.2f", low)
        highPercentage = prefs.defaultHighPercentage
        lowPercentage = prefs.defaultLowPercentage
        lowPercentageText = String(format: "%.1f", prefs.defaultLowPercentage)

        withAnimation(.easeIn(duration: 0.15)) {
            resetFlash = true
            showResetNotice = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                resetFlash = false
                showResetNotice = false
            }
        }
    }

    private func saveChanges() {
        guard let target = targetPrice, let low = lowPrice, let high = highPrice,
              low < high else { return }

        viewModel.updateStock(
            item: item,
            lowerThreshold: low,
            upperThreshold: high,
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

private struct DarkInputField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = "Enter value"
    var highlighted: Bool = false
    var onChange: (() -> Void)? = nil
    var onCommit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("WorkSans-Medium", size: 13))
                .foregroundStyle(Color.gray)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.custom("WorkSans-Regular", size: 15))
                        .foregroundStyle(AppColors.holdGray)
                }
                TextField("", text: Binding(
                    get: { text },
                    set: { newValue in
                        text = newValue
                        onChange?()
                    }
                ), onCommit: onCommit)
                    .decimalPadKeyboard()
                    .font(.custom("WorkSans-Regular", size: 15))
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(AppColors.inputDark)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(highlighted ? AppColors.buyGreen : AppColors.borderDark, lineWidth: highlighted ? 2 : 1))
        }
    }
}
