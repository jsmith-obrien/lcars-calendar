import SwiftUI

/// Third screen (calendar / config / weather), reached via the cloud icon in
/// HeaderBarView. Full-screen adaptation of ~/Projects/weather-widget's
/// WeatherPanelView (originally a 340pt menu-bar popover) — same data and
/// LCARS visual language, laid out for the iPad's width instead. Dismissed
/// via the X in the top-right, same as ConfigView's Done button dismisses it.
struct WeatherView: View {
    @StateObject private var service = WeatherService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            Rectangle()
                .fill(LCARS.orange)
                .frame(height: LCARS.Layout.dividerHeight)
                .padding(.horizontal, 8)

            HStack(spacing: 0) {
                currentConditionsPanel
                    .frame(width: 300)

                Rectangle().fill(LCARS.orange.opacity(0.3)).frame(width: LCARS.Layout.hairlineHeight)

                forecastList
            }

            Rectangle()
                .fill(LCARS.orange.opacity(0.3))
                .frame(height: LCARS.Layout.hairlineHeight)
                .padding(.horizontal, 12)

            footer

            FooterBarView()
        }
        .background(LCARS.black.ignoresSafeArea())
        .onAppear { service.startIfNeeded() }
        .onDisappear { service.stop() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: LCARS.Layout.elbowCornerRadius)
                .fill(LCARS.orange)
                .frame(width: 70, height: 36)
                .overlay(Text("LCARS").font(.system(size: 12, weight: .bold)).foregroundColor(.black))

            VStack(alignment: .leading, spacing: 1) {
                Text("WEATHER OPERATIONS").lcarsHeader(size: 15)
                Text("ATMOSPHERIC MONITORING SYSTEM")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARS.orange.opacity(0.5))
            }

            Spacer()

            statusPill

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LCARS.red))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(LCARS.dark)
    }

    private var statusPill: some View {
        Text(statusText)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(statusColor))
    }

    private var statusText: String {
        if service.isLoading { return "SYNC" }
        if service.errorMessage != nil { return "ERROR" }
        return "ONLINE"
    }

    private var statusColor: Color {
        if service.isLoading { return LCARS.blue }
        if service.errorMessage != nil { return LCARS.red }
        return LCARS.green
    }

    // MARK: - Current conditions

    private var currentConditionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: WeatherCondition.symbol(for: service.currentCode, isDay: service.isDay))
                .font(.system(size: 56))
                .foregroundColor(iconColor)

            HStack(alignment: .top, spacing: 2) {
                Text(service.currentTemp.map { "\($0)" } ?? "—")
                    .font(.system(size: 64, weight: .light, design: .monospaced))
                    .foregroundColor(LCARS.orange)
                Text("°F")
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
                    .foregroundColor(LCARS.orange.opacity(0.5))
                    .offset(y: 8)
            }

            Text(WeatherCondition.description(for: service.currentCode).uppercased())
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(LCARS.tan.opacity(0.7))

            if let today = service.forecast.first {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up").font(.system(size: 11, weight: .bold)).foregroundColor(LCARS.orange)
                        Text("\(today.high)°").font(.system(size: 15, weight: .medium, design: .monospaced)).foregroundColor(LCARS.orange)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down").font(.system(size: 11, weight: .bold)).foregroundColor(LCARS.blue)
                        Text("\(today.low)°").font(.system(size: 15, weight: .medium, design: .monospaced)).foregroundColor(LCARS.blue)
                    }
                }
            }

            Spacer()

            Text(service.locationLabel)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(LCARS.orange.opacity(0.4))
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var iconColor: Color {
        switch WeatherCondition.colorFamily(for: service.currentCode) {
        case "yellow": return LCARS.orange
        case "blue": return LCARS.blue
        case "cyan": return LCARS.ltblue
        case "purple": return LCARS.purple
        default: return LCARS.tan
        }
    }

    // MARK: - Forecast list

    private var forecastList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("7-DAY FORECAST")
                .lcarsLabel(size: 10, color: LCARS.pink, opacity: 1)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 6)

            if service.forecast.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    if service.isLoading {
                        ProgressView().tint(LCARS.orange)
                        Text("LOADING FORECAST...").lcarsLabel(size: 10)
                    } else if let error = service.errorMessage {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 28))
                            .foregroundColor(LCARS.red)
                        Text(error.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(LCARS.red)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(service.forecast) { day in
                            ForecastDayRow(day: day, tempRange: globalTempRange)
                            if day.id != service.forecast.last?.id {
                                Rectangle()
                                    .fill(LCARS.purple.opacity(0.15))
                                    .frame(height: 1)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
        }
    }

    private var globalTempRange: ClosedRange<Int> {
        guard !service.forecast.isEmpty else { return 0...100 }
        let lo = service.forecast.map(\.low).min() ?? 0
        let hi = service.forecast.map(\.high).max() ?? 100
        return lo...hi
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text(service.lastUpdatedText)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(LCARS.orange.opacity(0.4))

            Spacer()

            Button(action: { Task { await service.refresh() } }) {
                HStack(spacing: 4) {
                    if service.isLoading {
                        ProgressView().scaleEffect(0.7).tint(LCARS.orange)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text("REFRESH")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(LCARS.orange.opacity(0.7))
            }
            .buttonStyle(.plain)
            .disabled(service.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
