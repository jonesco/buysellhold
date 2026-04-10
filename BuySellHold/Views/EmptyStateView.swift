import SwiftUI

struct EmptyStateView: View {
    let onAddStock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Welcome,")
                .font(.custom("WorkSans-Regular", size: 32))
                .foregroundColor(.gray)
                .kerning(-0.4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Start tracking")
                    .font(.custom("WorkSans-Bold", size: 32))
                    .foregroundColor(AppColors.foreground)
                Text("Add a stock,\nset a baseline price.")
                    .font(.custom("WorkSans-Regular", size: 32))
                    .foregroundColor(.gray)
                    .kerning(-0.4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Set your range")
                    .font(.custom("WorkSans-Bold", size: 32))
                    .foregroundColor(AppColors.foreground)
                (
                    Text("Set a buy ").foregroundColor(.gray)
                    + Text("↓").foregroundColor(AppColors.buyGreen).font(.custom("WorkSans-Bold", size: 32))
                    + Text(" price\n").foregroundColor(.gray)
                    + Text("and sell ").foregroundColor(.gray)
                    + Text("↑").foregroundColor(AppColors.sellPurpleAlt).font(.custom("WorkSans-Bold", size: 32))
                    + Text(" price.").foregroundColor(.gray)
                )
                .font(.custom("WorkSans-Regular", size: 32))
                .kerning(-0.4)
            }

            Button(action: onAddStock) {
                Text("Add stock")
                    .font(.custom("WorkSans-SemiBold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.buyGreen)
                    .cornerRadius(8)
            }
            .containerRelativeFrame(.horizontal) { width, _ in width * 2 / 3 }
            .padding(.top, 32)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
