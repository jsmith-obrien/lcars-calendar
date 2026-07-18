import SwiftUI

/// LCARS palette — matches the Mac Studio design system (see AdaPhone/Theme.swift, lcars-fitness).
enum LCARS {
    static let black  = Color.black
    static let dark   = Color(red: 0.04, green: 0.04, blue: 0.10)
    static let mid    = Color(red: 0.08, green: 0.08, blue: 0.18)
    static let orange = Color(red: 1.00, green: 0.60, blue: 0.00)
    static let tan    = Color(red: 1.00, green: 0.80, blue: 0.60)
    static let pink   = Color(red: 0.80, green: 0.40, blue: 0.60)
    static let purple = Color(red: 0.60, green: 0.60, blue: 0.80)
    static let blue   = Color(red: 0.40, green: 0.60, blue: 0.80)
    static let ltblue = Color(red: 0.60, green: 0.80, blue: 1.00)
    static let green  = Color(red: 0.40, green: 1.00, blue: 0.40)
    static let red    = Color(red: 1.00, green: 0.20, blue: 0.00)

    static let faint = tan.opacity(0.4)
    static let hair  = orange.opacity(0.25)

    // Layout constants shared across the LCARS shell.
    enum Layout {
        static let elbowCornerRadius: CGFloat = 14
        static let cardCornerRadius: CGFloat = 6
        static let badgeCornerRadius: CGFloat = 8
        static let sidebarWidth: CGFloat = 150
        static let agendaWidth: CGFloat = 260
        static let dividerHeight: CGFloat = 3
        static let hairlineHeight: CGFloat = 1
        static let footerBarHeight: CGFloat = 6
    }
}

/// Convenience for turning a persisted hex string (e.g. from CalendarSource) back into a Color.
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

/// LCARS text is always uppercased — apply via `.lcarsText()` instead of repeating modifiers.
extension View {
    func lcarsHeader(size: CGFloat = 13, color: Color = LCARS.tan) -> some View {
        self.font(.system(size: size, weight: .bold)).foregroundColor(color).textCase(.uppercase)
    }

    func lcarsLabel(size: CGFloat = 9, color: Color = LCARS.orange, opacity: Double = 0.6) -> some View {
        self.font(.system(size: size, weight: .bold)).foregroundColor(color.opacity(opacity)).textCase(.uppercase)
    }

    func lcarsMono(size: CGFloat = 11, color: Color = LCARS.tan) -> some View {
        self.font(.system(size: size, weight: .bold, design: .monospaced)).foregroundColor(color)
    }
}
