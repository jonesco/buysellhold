import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum AppColors {
    // Brand
    static let buyGreen = Color(hex: "#16a34a")
    static let sellPurple = Color(hex: "#6b21a8")
    static let sellPurpleAlt = Color(hex: "#9333ea")
    static let holdGray = Color(hex: "#9ca3af")
    static let holdGrayDark = Color(hex: "#1e293b")

    // UI
    static let background = Color.white
    static let foreground = Color(hex: "#161616")
    static let secondaryText = Color(hex: "#4b5563")   // ~7.4:1 on white, AA compliant
    static let buyGreenDark = Color(hex: "#15803d")    // ~4.9:1 on white, AA compliant for normal text
    static let cardDark = Color(hex: "#181A20")
    static let inputDark = Color(hex: "#1E2026")
    static let borderDark = Color(hex: "#374151")
    static let link = Color(hex: "#818cf8")
    static let linkHover = Color(hex: "#6b77f0")

    // Accents
    static let accentGreenLight = Color(hex: "#dcfce7")
    static let accentPurpleLight = Color(hex: "#f3e8ff")
    static let greenGradientStart = Color(hex: "#dcfce7")
    static let purpleGradientStart = Color(hex: "#f3e8ff")
}
