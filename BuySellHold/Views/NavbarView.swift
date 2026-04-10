import SwiftUI

struct NavbarView: View {
    @Bindable var viewModel: WatchlistViewModel
    let watchlistCount: Int
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Top row: Logo and action buttons
            HStack {
                // Logo
                HStack(spacing: 0) {
                    Text("Buy")
                        .foregroundColor(AppColors.buyGreen)
                    + Text("\u{2193}")
                        .foregroundColor(AppColors.buyGreen)
                        .font(.custom("WorkSans-Bold", size: 28))
                    Text("Sell")
                        .foregroundColor(AppColors.sellPurpleAlt)
                    + Text("\u{2191}")
                        .foregroundColor(AppColors.sellPurpleAlt)
                        .font(.custom("WorkSans-Bold", size: 28))
                    Text("Hold")
                        .foregroundColor(AppColors.holdGrayDark)
                }
                .font(.custom("WorkSans-Bold", size: 24))

                Spacer()

                HStack(spacing: 16) {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    }

                    Button(action: { viewModel.showAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    }

                    Button(action: { viewModel.showSettingsSheet = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    }
                }
            }

            // Search and sort row (only when watchlist has items)
            if watchlistCount > 0 {
                HStack(spacing: 12) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        TextField("Search by symbol...", text: $viewModel.searchQuery)
                            .font(.custom("WorkSans-Medium", size: 16))
                            .foregroundColor(AppColors.foreground)
                            .disableAutocorrection(true)
                            .onChange(of: viewModel.searchQuery) { newValue in
                                let upper = newValue.uppercased()
                                if upper != newValue { viewModel.searchQuery = upper }
                            }

                        if !viewModel.searchQuery.isEmpty {
                            Button(action: { viewModel.searchQuery = "" }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#f9fafb"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                    // Sort menu
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { viewModel.setSortOption(option) }) {
                                HStack {
                                    Text(option.displayName)
                                    if viewModel.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14, weight: .medium))
                            Text("Sort")
                                .font(.custom("WorkSans-Medium", size: 13))
                        }
                        .foregroundColor(AppColors.foreground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .background(Color.white)
        .shadow(color: Color(hex: "#161616").opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

