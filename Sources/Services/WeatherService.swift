import Foundation

/// Ported from ~/Projects/weather-widget (macOS menu bar app), modernized to
/// async/await and a Task-based polling loop (matching CalendarViewModel's
/// pattern in this project) instead of Timer.scheduledTimer + a completion
/// handler. Location is still hardcoded to Rochester, NY, same as the
/// original — no location picker was asked for.
@MainActor
final class WeatherService: ObservableObject {
    @Published var currentTemp: Int?
    @Published var currentCode: Int = 0
    @Published var isDay: Bool = true
    @Published var forecast: [DayForecast] = []
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let locationLabel = "ROCHESTER, NY"
    private let latitude = 43.23
    private let longitude = -77.59
    private let timezone = "America/New_York"

    private var pollingTask: Task<Void, Never>?
    private let pollingInterval: TimeInterval = 900 // 15 minutes, matches the original widget

    func startIfNeeded() {
        guard pollingTask == nil else { return }
        Task { await refresh() }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let interval = self?.pollingInterval else { return }
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            components.queryItems = [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude)),
                URLQueryItem(name: "current", value: "temperature_2m,weather_code,is_day"),
                URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max"),
                URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
                URLQueryItem(name: "timezone", value: timezone),
                URLQueryItem(name: "forecast_days", value: "7"),
            ]
            guard let url = components.url else {
                errorMessage = "Bad URL"
                return
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                errorMessage = "HTTP \(http.statusCode)"
                return
            }

            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            if let current = decoded.current {
                currentTemp = Int(current.temperature2m.rounded())
                currentCode = current.weatherCode
                isDay = (current.isDay ?? 1) == 1
            }
            forecast = Self.buildForecast(from: decoded.daily, timezone: timezone)
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func buildForecast(from daily: DailyForecast?, timezone: String) -> [DayForecast] {
        guard let daily else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: timezone)

        var days: [DayForecast] = []
        for i in 0..<daily.time.count {
            guard let date = formatter.date(from: daily.time[i]) else { continue }
            days.append(DayForecast(
                id: daily.time[i],
                date: date,
                high: Int(daily.temperatureMax[i].rounded()),
                low: Int(daily.temperatureMin[i].rounded()),
                weatherCode: daily.weatherCode[i],
                precipChance: daily.precipitationProbabilityMax[i]
            ))
        }
        return days
    }

    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "NEVER" }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date).uppercased()
    }
}
