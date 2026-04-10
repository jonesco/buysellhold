import SwiftUI

struct StockCardView: View {
    let item: WatchlistItem
    @Bindable var viewModel: WatchlistViewModel

    @State private var isExpanded = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    private var price: Double { viewModel.currentPrice(for: item) }
    private var change: (dollar: Double, percent: Double) { viewModel.priceChange(for: item) }
    private var lowPercent: Double { viewModel.lowPercentage(for: item) }
    private var highPercent: Double { viewModel.highPercentage(for: item) }

    private var sliderPercent: Double {
        let range = item.upperThreshold - item.lowerThreshold
        guard range > 0 else { return 50 }
        return max(0, min(100, ((price - item.lowerThreshold) / range) * 100))
    }

    private var isBuy: Bool { price <= item.lowerThreshold }
    private var isSell: Bool { price >= item.upperThreshold }

    private var backgroundGradient: some View {
        Group {
            if isBuy {
                LinearGradient(
                    colors: [AppColors.greenGradientStart, .white],
                    startPoint: .leading, endPoint: .trailing
                )
            } else if isSell {
                LinearGradient(
                    colors: [AppColors.purpleGradientStart, .white],
                    startPoint: .leading, endPoint: .trailing
                )
            } else {
                LinearGradient(
                    colors: [Color(hex: "#f9fafb"), Color(hex: "#f9fafb")],
                    startPoint: .leading, endPoint: .trailing
                )
            }
        }
    }

    private var borderColor: Color? {
        if isBuy { return AppColors.buyGreen }
        if isSell { return AppColors.sellPurple }
        return nil
    }

    private var changeColor: Color {
        if change.dollar > 0 { return AppColors.buyGreen }
        if change.dollar < 0 { return AppColors.sellPurple }
        return AppColors.holdGray
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    // Ticker + last updated
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            let query = "Recommendation on buying \(item.stockSymbol) right now."
                            if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                               let url = URL(string: "https://www.google.com/search?q=\(encoded)&udm=50") {
                                openURL(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(item.stockSymbol)
                                    .font(.custom("WorkSans-SemiBold", size: 22))
                                    .foregroundColor(AppColors.foreground)
                                Image(systemName: "safari")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                        Text(relativeDate(item.updatedAt))
                            .font(.custom("WorkSans-Regular", size: 11))
                            .foregroundColor(.gray)
                    }
                    .frame(minWidth: 80, alignment: .leading)

                    // Price + change
                    VStack(alignment: .leading, spacing: 0) {
                        Text("$\(price, specifier: "%.2f")")
                            .font(.custom("WorkSans-SemiBold", size: 18))
                            .monospacedDigit()
                            .foregroundColor(AppColors.foreground)

                        HStack(spacing: 2) {
                            if change.dollar > 0 {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppColors.buyGreen)
                            } else if change.dollar < 0 {
                                Image(systemName: "arrow.down.left")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppColors.sellPurple)
                            }
                            Text("\(change.dollar >= 0 ? "+" : "")\(change.dollar, specifier: "%.2f") (\(change.percent >= 0 ? "+" : "")\(change.percent, specifier: "%.2f")%)")
                                .font(.custom("WorkSans-Medium", size: 12))
                                .monospacedDigit()
                                .foregroundColor(changeColor)
                        }
                    }
                    .frame(minWidth: 100, alignment: .leading)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: { showEditSheet = true }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        Button(action: { showDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        Button(action: { withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() } }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(16)

                // Expanded slider area
                if isExpanded {
                    SliderSection(
                        lowPrice: item.lowerThreshold,
                        highPrice: item.upperThreshold,
                        targetPrice: item.targetPrice,
                        lowPercent: lowPercent,
                        highPercent: highPercent,
                        sliderPercent: sliderPercent
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeOut(duration: 0.2), value: isExpanded)
                }
            }
            .background(backgroundGradient)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor ?? .clear, lineWidth: borderColor != nil ? 4 : 0)
            )
            .shadow(color: Color(hex: "#161616").opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .sheet(isPresented: $showEditSheet) {
            EditStockSheet(
                item: item,
                viewModel: viewModel
            )
        }
        .confirmationDialog(
            "Delete \(item.stockSymbol)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteStock(item: item, context: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \(item.stockSymbol) from your watchlist?")
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days) days ago"
    }
}

struct SliderSection: View {
    let lowPrice: Double
    let highPrice: Double
    let targetPrice: Double
    let lowPercent: Double
    let highPercent: Double
    let sliderPercent: Double

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Low
                VStack(spacing: 2) {
                    Text("Low")
                        .font(.custom("WorkSans-Regular", size: 12))
                        .foregroundColor(.gray)
                    Text("$\(lowPrice, specifier: "%.2f")")
                        .font(.custom("WorkSans-Medium", size: 13))
                        .monospacedDigit()
                        .foregroundColor(AppColors.foreground)
                    Text("\(lowPercent, specifier: "%.2f")%")
                        .font(.custom("WorkSans-Regular", size: 11))
                        .monospacedDigit()
                        .foregroundColor(AppColors.buyGreen)
                }
                .frame(minWidth: 60)

                // Slider track
                GeometryReader { geo in
                    let trackWidth = geo.size.width
                    let indicatorX = trackWidth * sliderPercent / 100

                    VStack(spacing: 0) {
                        // Target price label
                        Text("$\(targetPrice, specifier: "%.2f")")
                            .font(.custom("WorkSans-SemiBold", size: 11))
                            .monospacedDigit()
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(2)
                            .offset(x: indicatorX - trackWidth / 2)

                        // Triangle indicator
                        Triangle()
                            .fill(AppColors.borderDark)
                            .frame(width: 12, height: 6)
                            .offset(x: indicatorX - trackWidth / 2)

                        // Track line
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .padding(.top, 2)
                    }
                }
                .frame(height: 40)

                // High
                VStack(spacing: 2) {
                    Text("High")
                        .font(.custom("WorkSans-Regular", size: 12))
                        .foregroundColor(.gray)
                    Text("$\(highPrice, specifier: "%.2f")")
                        .font(.custom("WorkSans-Medium", size: 13))
                        .monospacedDigit()
                        .foregroundColor(AppColors.foreground)
                    Text("\(highPercent, specifier: "%.2f")%")
                        .font(.custom("WorkSans-Regular", size: 11))
                        .monospacedDigit()
                        .foregroundColor(AppColors.sellPurple)
                }
                .frame(minWidth: 60)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
