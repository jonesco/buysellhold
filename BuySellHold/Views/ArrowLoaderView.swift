import SwiftUI

struct ArrowLoaderView: View {
    @State private var greenOffset: CGFloat = -50
    @State private var purpleOffset: CGFloat = 50
    @State private var greenOpacity: Double = 0
    @State private var purpleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Green arrow (down) - matching header style
            Text("\u{2193}")
                .font(.custom("WorkSans-Bold", size: 80))
                .foregroundColor(AppColors.buyGreen)
                .offset(x: -20, y: greenOffset)
                .opacity(greenOpacity)

            // Purple arrow (up) - matching header style
            Text("\u{2191}")
                .font(.custom("WorkSans-Bold", size: 80))
                .foregroundColor(AppColors.sellPurple)
                .offset(x: 20, y: purpleOffset)
                .opacity(purpleOpacity)
        }
        .frame(width: 144, height: 144)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                greenOffset = -20
                greenOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5)) {
                purpleOffset = 20
                purpleOpacity = 1
            }
        }
    }
}
