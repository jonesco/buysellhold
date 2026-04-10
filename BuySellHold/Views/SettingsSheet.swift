import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: WatchlistViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    NavigationLink {
                        ApiKeySettingsView()
                    } label: {
                        SettingsMenuRow(
                            icon: "key.fill",
                            title: "API Keys"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        PreferencesSettingsView(viewModel: viewModel)
                    } label: {
                        SettingsMenuRow(
                            icon: "slider.horizontal.3",
                            title: "Preferences"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        BackupSettingsView(viewModel: viewModel)
                    } label: {
                        SettingsMenuRow(
                            icon: "square.and.arrow.up.on.square",
                            title: "Backup"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(AppColors.cardDark)
            .navigationTitle("Settings")
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
}

private struct SettingsMenuRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(AppColors.inputDark)
                .cornerRadius(8)

            Text(title)
                .font(.custom("WorkSans-Medium", size: 20))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .center)
        .padding(14)
        .background(AppColors.inputDark)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderDark, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct ApiKeySettingsView: View {
    @AppStorage("finnhubApiKeyStored") private var finnhubApiKeyStored: Bool = false

    @State private var finnhubKeyText: String = ""
    @State private var isFinnhubVisible = false
    @State private var isTestingFinnhub = false
    @State private var finnhubMessage: (type: String, text: String)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // MARK: Finnhub
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Finnhub — Live Prices")
                            .font(.custom("WorkSans-Medium", size: 17))
                            .foregroundColor(.white)
                        Text("Required for fetching real-time stock quotes. Free account at finnhub.io.")
                            .font(.custom("WorkSans-Regular", size: 13))
                            .foregroundColor(.gray)
                        Link("Get a free key at finnhub.io →", destination: URL(string: "https://finnhub.io/register")!)
                            .font(.custom("WorkSans-Medium", size: 13))
                            .foregroundColor(AppColors.link)
                    }

                    ApiKeyInputRow(keyText: $finnhubKeyText, isVisible: $isFinnhubVisible, placeholder: "Paste your Finnhub API key")

                    if let msg = finnhubMessage { ApiKeyStatusMessage(message: msg) }

                    HStack {
                        Button(action: testFinnhub) {
                            Text(isTestingFinnhub ? "Testing..." : "Test")
                                .font(.custom("WorkSans-Medium", size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(finnhubKeyText.trimmed.isEmpty || isTestingFinnhub ? AppColors.inputDark.opacity(0.5) : AppColors.inputDark)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))
                        }
                        .disabled(finnhubKeyText.trimmed.isEmpty || isTestingFinnhub)
                        Spacer()
                        if finnhubApiKeyStored {
                            Button(action: clearFinnhub) {
                                Text("Clear")
                                    .font(.custom("WorkSans-Medium", size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))
                                    .cornerRadius(8)
                            }
                        }
                        Button(action: saveFinnhub) {
                            Text("Save")
                                .font(.custom("WorkSans-Medium", size: 14))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(finnhubKeyText.trimmed.isEmpty ? Color.white.opacity(0.5) : Color.white)
                                .cornerRadius(8)
                        }
                        .disabled(finnhubKeyText.trimmed.isEmpty)
                    }

                    if finnhubApiKeyStored { savedBadge }
                }
            }
            .padding(20)
        }
        .background(AppColors.cardDark)
        .navigationTitle("API Keys")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppColors.cardDark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .onAppear {
            finnhubKeyText = KeychainHelper.get(account: "finnhubApiKey") ?? ""
        }
    }

    private var savedBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(AppColors.buyGreen).font(.system(size: 12))
            Text("Key saved").font(.custom("WorkSans-Regular", size: 12)).foregroundColor(.gray)
        }
    }

    private func testFinnhub() {
        isTestingFinnhub = true; finnhubMessage = nil
        Task {
            let valid = await FinnhubService.shared.validateApiKey(finnhubKeyText.trimmed)
            await MainActor.run {
                isTestingFinnhub = false
                finnhubMessage = valid ? ("success", "Key is valid!") : ("error", "Key test failed. Double-check and try again.")
            }
        }
    }

    private func saveFinnhub() {
        KeychainHelper.set(finnhubKeyText.trimmed, account: "finnhubApiKey")
        finnhubApiKeyStored = true
        finnhubMessage = ("success", "Finnhub key saved.")
    }

    private func clearFinnhub() {
        KeychainHelper.delete(account: "finnhubApiKey")
        finnhubApiKeyStored = false
        finnhubKeyText = ""
        finnhubMessage = nil
    }
}

private struct ApiKeyInputRow: View {
    @Binding var keyText: String
    @Binding var isVisible: Bool
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                if keyText.isEmpty {
                    Text(placeholder)
                        .font(.custom("WorkSans-Regular", size: 14))
                        .foregroundColor(AppColors.holdGray)
                }
                if isVisible {
                    TextField("", text: $keyText)
                        .font(.custom("WorkSans-Regular", size: 14))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } else {
                    SecureField("", text: $keyText)
                        .font(.custom("WorkSans-Regular", size: 14))
                        .foregroundColor(.white)
                }
            }
            .padding(10)
            .background(AppColors.inputDark)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))

            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
                    .frame(width: 32, height: 32)
            }
        }
    }
}

private struct ApiKeyStatusMessage: View {
    let message: (type: String, text: String)
    var body: some View {
        Text(message.text)
            .font(.custom("WorkSans-Regular", size: 12))
            .foregroundColor(message.type == "success" ? AppColors.buyGreen : .red)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(message.type == "success" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(message.type == "success" ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1))
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

private struct PreferencesSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: WatchlistViewModel

    @State private var highPercentage: Double = 10
    @State private var lowPercentage: Double = -10
    @State private var highPercentageText: String = "10"
    @State private var lowPercentageText: String = "-10"
    @State private var message: (type: String, text: String)?
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Threshold Percentages")
                        .font(.custom("WorkSans-Medium", size: 18))
                        .foregroundColor(.white)
                    Text("Set your preferred default percentages for new stocks. These will be used when adding stocks to your watchlist.")
                        .font(.custom("WorkSans-Regular", size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Default High Percentage")
                        .font(.custom("WorkSans-Medium", size: 13))
                        .foregroundColor(.gray)
                    HStack {
                        ZStack(alignment: .leading) {
                            if highPercentageText.isEmpty {
                                Text("e.g. 10")
                                    .font(.custom("WorkSans-Regular", size: 15))
                                    .foregroundColor(AppColors.holdGray)
                            }
                            TextField("", text: $highPercentageText)
                                .decimalPadKeyboard()
                                .font(.custom("WorkSans-Regular", size: 15))
                                .foregroundColor(Color.white)
                                .onChange(of: highPercentageText) { _, newValue in
                                    if let val = Double(newValue) { highPercentage = val }
                                }
                        }
                        .padding(10)
                        .background(AppColors.inputDark)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))

                        Text("%")
                            .font(.custom("WorkSans-Regular", size: 15))
                            .foregroundColor(.gray)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Low Percentage")
                        .font(.custom("WorkSans-Medium", size: 13))
                        .foregroundColor(.gray)
                    HStack {
                        ZStack(alignment: .leading) {
                            if lowPercentageText.isEmpty {
                                Text("e.g. -10")
                                    .font(.custom("WorkSans-Regular", size: 15))
                                    .foregroundColor(AppColors.holdGray)
                            }
                            TextField("", text: $lowPercentageText)
                                .numbersAndPunctuationKeyboard()
                                .font(.custom("WorkSans-Regular", size: 15))
                                .foregroundColor(Color.white)
                                .onChange(of: lowPercentageText) { _, newValue in
                                    let normalized = normalizedLowPercentageText(newValue)
                                    if normalized != newValue {
                                        lowPercentageText = normalized
                                    }
                                    if let parsed = parsedLowPercentage(from: normalized) {
                                        lowPercentage = parsed
                                    }
                                }
                        }
                        .padding(10)
                        .background(AppColors.inputDark)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.borderDark, lineWidth: 1))

                        Text("%")
                            .font(.custom("WorkSans-Regular", size: 15))
                            .foregroundColor(.gray)
                    }
                }

                if let msg = message {
                    Text(msg.text)
                        .font(.custom("WorkSans-Regular", size: 13))
                        .foregroundColor(msg.type == "success" ? AppColors.buyGreen : .red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(msg.type == "success" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(msg.type == "success" ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                }

                HStack {
                    Spacer()
                    Button(action: savePreferences) {
                        Text(isSaving ? "Saving..." : "Save Preferences")
                            .font(.custom("WorkSans-Medium", size: 15))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(highPercentage <= lowPercentage || isSaving ? Color.white.opacity(0.5) : Color.white)
                            .cornerRadius(8)
                    }
                    .disabled(highPercentage <= lowPercentage || isSaving)
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(AppColors.cardDark)
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppColors.cardDark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .onAppear(perform: loadPreferences)
    }

    private func loadPreferences() {
        let prefs = viewModel.getPreferences(context: modelContext)
        highPercentage = prefs.defaultHighPercentage
        lowPercentage = prefs.defaultLowPercentage
        highPercentageText = String(format: "%.1f", prefs.defaultHighPercentage)
        lowPercentageText = String(format: "%.1f", prefs.defaultLowPercentage)
    }

    private func savePreferences() {
        guard highPercentage > lowPercentage else {
            message = ("error", "High percentage must be greater than low percentage")
            return
        }

        isSaving = true
        let prefs = viewModel.getPreferences(context: modelContext)
        prefs.defaultHighPercentage = highPercentage
        prefs.defaultLowPercentage = lowPercentage
        try? modelContext.save()

        message = ("success", "Preferences saved successfully!")
        isSaving = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
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

private struct BackupSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: WatchlistViewModel

    @State private var message: (type: String, text: String)?
    @State private var exportDocument: WatchlistBackupDocument?
    @State private var exportFilename: String = "BuySellHold_Watchlist"
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingImportBackup: WatchlistBackup?
    @State private var showImportModeDialog = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Export your current watchlist as a timestamped JSON file, then import it later. Import supports merge or full replace.")
                    .font(.custom("WorkSans-Regular", size: 14))
                    .foregroundColor(.gray)

                HStack(spacing: 10) {
                    Button(action: exportWatchlist) {
                        Text("Export JSON")
                            .font(.custom("WorkSans-Medium", size: 14))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.white)
                            .cornerRadius(8)
                    }

                    Button(action: { isImporting = true }) {
                        Text("Import JSON")
                            .font(.custom("WorkSans-Medium", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(AppColors.inputDark)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.borderDark, lineWidth: 1)
                            )
                    }
                }

                if let msg = message {
                    Text(msg.text)
                        .font(.custom("WorkSans-Regular", size: 13))
                        .foregroundColor(msg.type == "success" ? AppColors.buyGreen : .red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(msg.type == "success" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(msg.type == "success" ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                }

                Text("Replace removes your current watchlist and imports the file. Merge updates matching symbols and adds missing ones.")
                    .font(.custom("WorkSans-Regular", size: 12))
                    .foregroundColor(.gray)
            }
            .padding(20)
        }
        .background(AppColors.cardDark)
        .navigationTitle("Backup")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppColors.cardDark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success:
                message = ("success", "Watchlist exported successfully.")
            case .failure(let error):
                message = ("error", "Export failed: \(error.localizedDescription)")
            }
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .confirmationDialog(
            "Import Watchlist",
            isPresented: $showImportModeDialog,
            titleVisibility: .visible
        ) {
            Button("Merge with Current Watchlist") {
                applyImport(mode: .merge)
            }
            Button("Replace Current Watchlist", role: .destructive) {
                applyImport(mode: .replace)
            }
            Button("Cancel", role: .cancel) {
                pendingImportBackup = nil
            }
        } message: {
            Text("Choose how to apply the imported stock list.")
        }
    }

    private func exportWatchlist() {
        let currentItems = fetchAllWatchlistItems()
        guard !currentItems.isEmpty else {
            message = ("error", "No stocks to export yet.")
            return
        }

        let exportedAt = Date()
        let backupItems = currentItems.map { item in
            WatchlistBackupItem(
                stockSymbol: item.stockSymbol,
                companyName: item.companyName,
                currentPrice: item.currentPrice,
                lowerThreshold: item.lowerThreshold,
                upperThreshold: item.upperThreshold,
                initialPrice: item.initialPrice,
                targetPrice: item.targetPrice,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt
            )
        }
        let backup = WatchlistBackup(version: 1, exportedAt: exportedAt, items: backupItems)
        exportDocument = WatchlistBackupDocument(backup: backup)
        exportFilename = "BuySellHold_Watchlist_\(Self.exportTimestampFormatter.string(from: exportedAt))"
        isExporting = true
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            message = ("error", "Import failed: \(error.localizedDescription)")
        case .success(let urls):
            guard let url = urls.first else {
                message = ("error", "No file selected.")
                return
            }

            do {
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if hasAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                let backup = try WatchlistBackup.decode(from: data)
                guard !backup.items.isEmpty else {
                    message = ("error", "The selected file has no stock entries.")
                    return
                }

                pendingImportBackup = backup
                showImportModeDialog = true
            } catch {
                message = ("error", "Unable to read JSON backup.")
            }
        }
    }

    private func applyImport(mode: ImportMode) {
        guard let backup = pendingImportBackup else { return }
        pendingImportBackup = nil

        do {
            let importedBySymbol = backup.items
                .map { $0.normalized() }
                .reduce(into: [String: WatchlistBackupItem]()) { partial, item in
                    partial[item.stockSymbol] = item
                }

            var inserted = 0
            var updated = 0
            var removed = 0

            var existingItems = fetchAllWatchlistItems()
            if mode == .replace {
                removed = existingItems.count
                for item in existingItems {
                    modelContext.delete(item)
                }
                existingItems = []
                viewModel.livePrices.removeAll()
            }

            var existingBySymbol = existingItems.reduce(into: [String: WatchlistItem]()) { partial, item in
                partial[item.stockSymbol.uppercased()] = item
            }

            for imported in importedBySymbol.values.sorted(by: { $0.stockSymbol < $1.stockSymbol }) {
                if let existing = existingBySymbol[imported.stockSymbol], mode == .merge {
                    existing.companyName = imported.companyName
                    existing.currentPrice = imported.currentPrice
                    existing.lowerThreshold = imported.lowerThreshold
                    existing.upperThreshold = imported.upperThreshold
                    existing.initialPrice = imported.initialPrice
                    existing.targetPrice = imported.targetPrice
                    existing.updatedAt = imported.updatedAt ?? Date()
                    if let createdAt = imported.createdAt {
                        existing.createdAt = createdAt
                    }
                    updated += 1
                } else {
                    let item = WatchlistItem(
                        stockSymbol: imported.stockSymbol,
                        companyName: imported.companyName,
                        currentPrice: imported.currentPrice,
                        lowerThreshold: imported.lowerThreshold,
                        upperThreshold: imported.upperThreshold,
                        initialPrice: imported.initialPrice,
                        targetPrice: imported.targetPrice
                    )
                    item.createdAt = imported.createdAt ?? Date()
                    item.updatedAt = imported.updatedAt ?? Date()
                    modelContext.insert(item)
                    existingBySymbol[item.stockSymbol.uppercased()] = item
                    inserted += 1
                }
            }

            try modelContext.save()
            message = (
                "success",
                mode == .replace
                    ? "Import complete: added \(inserted) stocks and replaced \(removed) existing entries."
                    : "Import complete: added \(inserted) stocks, updated \(updated) existing entries."
            )
        } catch {
            message = ("error", "Import failed while applying data.")
        }
    }

    private func fetchAllWatchlistItems() -> [WatchlistItem] {
        let descriptor = FetchDescriptor<WatchlistItem>(sortBy: [SortDescriptor(\.stockSymbol)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private static let exportTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

private enum ImportMode {
    case merge
    case replace
}

private struct WatchlistBackup: Codable {
    let version: Int
    let exportedAt: Date
    let items: [WatchlistBackupItem]

    static func decode(from data: Data) throws -> WatchlistBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WatchlistBackup.self, from: data)
    }
}

private struct WatchlistBackupItem: Codable {
    let stockSymbol: String
    let companyName: String
    let currentPrice: Double
    let lowerThreshold: Double
    let upperThreshold: Double
    let initialPrice: Double
    let targetPrice: Double
    let createdAt: Date?
    let updatedAt: Date?

    func normalized() -> WatchlistBackupItem {
        WatchlistBackupItem(
            stockSymbol: stockSymbol.uppercased(),
            companyName: companyName,
            currentPrice: currentPrice,
            lowerThreshold: lowerThreshold,
            upperThreshold: upperThreshold,
            initialPrice: initialPrice,
            targetPrice: targetPrice,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct WatchlistBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let backup: WatchlistBackup

    init(backup: WatchlistBackup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        backup = try WatchlistBackup.decode(from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        return FileWrapper(regularFileWithContents: data)
    }
}
