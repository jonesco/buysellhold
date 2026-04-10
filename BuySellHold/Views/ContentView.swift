import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WatchlistItem.stockSymbol) private var watchlistItems: [WatchlistItem]
    @State private var viewModel = WatchlistViewModel()
    @State private var hasInitiallyLoaded = false
    @State private var contentOpacity: Double = 0
    @AppStorage("finnhubApiKeyStored") private var finnhubApiKeyStored: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Navbar
            NavbarView(
                viewModel: viewModel,
                watchlistCount: watchlistItems.count,
                onRefresh: refreshPrices
            )

            // Content
            if viewModel.showLoader {
                Spacer()
                VStack(spacing: 16) {
                    ArrowLoaderView()
                    Text("Loading your watchlist...")
                        .font(.custom("WorkSans-Medium", size: 15))
                        .foregroundColor(AppColors.secondaryText)
                }
                Spacer()
            } else {
                let sorted = viewModel.filteredAndSorted(watchlistItems)

                if sorted.isEmpty && viewModel.searchQuery.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(onAddStock: { viewModel.showAddSheet = true })
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 150)
                    .opacity(contentOpacity)
                    .animation(.easeOut(duration: 0.25), value: contentOpacity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if sorted.isEmpty {
                                // No search results
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No results found")
                                        .font(.custom("WorkSans-SemiBold", size: 18))
                                        .foregroundColor(AppColors.secondaryText)
                                    Text("No stocks match \"\(viewModel.searchQuery)\"")
                                        .font(.custom("WorkSans-Medium", size: 14))
                                        .foregroundColor(AppColors.secondaryText)
                                    Button(action: { viewModel.searchQuery = "" }) {
                                        Text("Clear search")
                                            .font(.custom("WorkSans-Medium", size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.gray)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 60)
                            } else {
                                ForEach(sorted) { item in
                                    StockCardView(item: item, viewModel: viewModel)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 60)
                    }
                    .refreshable {
                        await refreshPricesAsync()
                    }
                    .opacity(contentOpacity)
                    .animation(.easeOut(duration: 0.25), value: contentOpacity)
                }
            }
        }
        .background(Color.white)
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddStockSheet(
                viewModel: viewModel,
                existingSymbols: watchlistItems.map(\.stockSymbol)
            )
        }
        .sheet(isPresented: $viewModel.showSettingsSheet) {
            SettingsSheet(viewModel: viewModel)
        }
        .overlay {
            if !finnhubApiKeyStored && !viewModel.showSettingsSheet {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: !finnhubApiKeyStored && !viewModel.showSettingsSheet)
        .task {
            if !hasInitiallyLoaded {
                viewModel.startLoading()
                await viewModel.fetchLivePrices(for: watchlistItems)
                viewModel.finishLoading()
                hasInitiallyLoaded = true
                contentOpacity = 1
            }
        }
        .onChange(of: viewModel.showContent) { _, show in
            if show {
                contentOpacity = 1
            }
        }
    }

    private func refreshPrices() {
        Task {
            await refreshPricesAsync()
        }
    }

    private func refreshPricesAsync() async {
        await viewModel.fetchLivePrices(for: watchlistItems)
    }
}
