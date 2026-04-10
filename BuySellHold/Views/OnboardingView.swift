import SwiftUI

struct OnboardingView: View {
    @AppStorage("finnhubApiKeyStored") private var finnhubApiKeyStored: Bool = false

    @State private var pendingKey = ""
    @State private var isVisible = false
    @State private var isTesting = false
    @State private var testMessage: (type: String, text: String)?

    var body: some View {
        VStack(spacing: 0) {
            // Identical to NavbarView header, buttons hidden
            HStack {
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .background(Color.white)
            .shadow(color: Color(hex: "#161616").opacity(0.1), radius: 2, x: 0, y: 1)

            // Dark sheet fills the rest
            sheetContent
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(edges: .bottom)
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Set up live\nprice tracking")
                    .font(.custom("WorkSans-Bold", size: 32))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                Text("BuySellHold uses Finnhub to fetch real-time stock quotes. Create a free account, then paste your API key below.")
                    .font(.custom("WorkSans-Regular", size: 15))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                Link("Get a free key at finnhub.io →", destination: URL(string: "https://finnhub.io/register")!)
                    .font(.custom("WorkSans-Medium", size: 14))
                    .foregroundColor(AppColors.link)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Finnhub API Key")
                    .font(.custom("WorkSans-Medium", size: 13))
                    .foregroundColor(.gray)

                HStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if pendingKey.isEmpty {
                            Text("Paste your Finnhub API key")
                                .font(.custom("WorkSans-Regular", size: 15))
                                .foregroundColor(AppColors.holdGray)
                        }
                        if isVisible {
                            TextField("", text: $pendingKey)
                                .font(.custom("WorkSans-Regular", size: 15))
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                #endif
                        } else {
                            SecureField("", text: $pendingKey)
                                .font(.custom("WorkSans-Regular", size: 15))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(12)
                    .background(AppColors.inputDark)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.borderDark, lineWidth: 1))

                    Button(action: { isVisible.toggle() }) {
                        Image(systemName: isVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                            .frame(width: 36, height: 36)
                    }
                }
            }

            if let msg = testMessage {
                onboardingStatusMessage(msg)
            }

            VStack(spacing: 12) {
                Button(action: testKey) {
                    HStack {
                        if isTesting { ProgressView().tint(.white).scaleEffect(0.8) }
                        Text(isTesting ? "Testing..." : "Test Key")
                            .font(.custom("WorkSans-Medium", size: 15))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(pendingKey.trimmed.isEmpty || isTesting ? AppColors.inputDark.opacity(0.5) : AppColors.inputDark)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.borderDark, lineWidth: 1))
                }
                .disabled(pendingKey.trimmed.isEmpty || isTesting)

                Button(action: finish) {
                    Text("Get Started")
                        .font(.custom("WorkSans-SemiBold", size: 15))
                        .foregroundColor(AppColors.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(pendingKey.trimmed.isEmpty ? Color.white.opacity(0.4) : Color.white)
                        .cornerRadius(12)
                }
                .disabled(pendingKey.trimmed.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 36)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.cardDark)
    }

    private func onboardingStatusMessage(_ msg: (type: String, text: String)) -> some View {
        Text(msg.text)
            .font(.custom("WorkSans-Regular", size: 13))
            .foregroundColor(msg.type == "success" ? AppColors.buyGreen : .red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(msg.type == "success" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                msg.type == "success" ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1
            ))
    }

    private func testKey() {
        isTesting = true; testMessage = nil
        Task {
            let valid = await FinnhubService.shared.validateApiKey(pendingKey.trimmed)
            await MainActor.run {
                isTesting = false
                testMessage = valid
                    ? ("success", "Key is valid! Tap Get Started to continue.")
                    : ("error", "Key test failed. Double-check the key and try again.")
            }
        }
    }

    private func finish() {
        KeychainHelper.set(pendingKey.trimmed, account: "finnhubApiKey")
        finnhubApiKeyStored = true
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
