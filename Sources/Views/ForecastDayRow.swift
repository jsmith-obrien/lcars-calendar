import SwiftUI

/// Ported from ~/Projects/weather-widget's ForecastDayRow, resized for an
/// iPad screen instead of a 340pt menu-bar popover and using this project's
/// own LCARS enum (Theme.swift) instead of the widget's separate Color
/// extension of the same palette.
struct ForecastDayRow: View {
    let day: DayForecast
    let tempRange: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 0) {
            Text(day.dayName.uppercased())
                .font(.system(size: 12, weight: day.dayName == "Today" ? .bold : .medium, design: .monospaced))
                .foregroundColor(day.dayName == "Today" ? LCARS.orange : LCARS.tan.opacity(0.7))
                .frame(width: 100, alignment: .leading)

            Image(systemName: WeatherCondition.symbol(for: day.weatherCode))
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 32)

            Text(day.precipChance > 0 ? "\(day.precipChance)%" : "")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(LCARS.blue.opacity(0.7))
                .frame(width: 44, alignment: .trailing)

            Spacer().frame(width: 12)

            Text("\(day.low)°")
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(LCARS.blue.opacity(0.6))
                .frame(width: 38, alignment: .trailing)

            Spacer().frame(width: 8)

            GeometryReader { geo in
                let totalSpan = max(CGFloat(tempRange.upperBound - tempRange.lowerBound), 1)
                let barStart = CGFloat(day.low - tempRange.lowerBound) / totalSpan
                let barEnd = CGFloat(day.high - tempRange.lowerBound) / totalSpan

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LCARS.dark)
                        .frame(height: 5)

                    Capsule()
                        .fill(barGradient)
                        .frame(width: max((barEnd - barStart) * geo.size.width, 4), height: 5)
                        .offset(x: barStart * geo.size.width)
                }
                .frame(height: geo.size.height)
            }
            .frame(height: 5)
            .frame(maxWidth: .infinity)

            Spacer().frame(width: 8)

            Text("\(day.high)°")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(LCARS.orange)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var iconColor: Color {
        switch WeatherCondition.colorFamily(for: day.weatherCode) {
        case "yellow": return LCARS.orange
        case "blue": return LCARS.blue
        case "cyan": return LCARS.ltblue
        case "purple": return LCARS.purple
        default: return LCARS.tan.opacity(0.5)
        }
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [LCARS.blue, LCARS.ltblue, LCARS.green, LCARS.tan, LCARS.orange, LCARS.red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
