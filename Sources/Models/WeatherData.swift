import Foundation

// Ported from ~/Projects/weather-widget (macOS menu bar app) — pure
// Foundation types, no changes needed for iPadOS.

// MARK: - API Response Models

struct OpenMeteoResponse: Decodable {
    let current: CurrentWeather?
    let daily: DailyForecast?
}

struct CurrentWeather: Decodable {
    let temperature2m: Double
    let weatherCode: Int
    let isDay: Int?

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case isDay = "is_day"
    }
}

struct DailyForecast: Decodable {
    let time: [String]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let weatherCode: [Int]
    let precipitationProbabilityMax: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case weatherCode = "weather_code"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}

// MARK: - Display Model

struct DayForecast: Identifiable {
    let id: String
    let date: Date
    let high: Int
    let low: Int
    let weatherCode: Int
    let precipChance: Int

    var dayName: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }

    var fullDayName: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE"
        return fmt.string(from: date)
    }
}

// MARK: - Weather Code -> SF Symbol + Description

enum WeatherCondition {
    static func symbol(for code: Int, isDay: Bool = true) -> String {
        switch code {
        case 0:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1:
            return isDay ? "sun.min.fill" : "moon.fill"
        case 2:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55:
            return "cloud.drizzle.fill"
        case 56, 57:
            return "cloud.sleet.fill"
        case 61, 63, 65:
            return "cloud.rain.fill"
        case 66, 67:
            return "cloud.sleet.fill"
        case 71, 73, 75:
            return "cloud.snow.fill"
        case 77:
            return "snowflake"
        case 80, 81, 82:
            return "cloud.heavyrain.fill"
        case 85, 86:
            return "cloud.snow.fill"
        case 95:
            return "cloud.bolt.fill"
        case 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "questionmark.circle"
        }
    }

    static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1: return "Mostly Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing Drizzle"
        case 61: return "Light Rain"
        case 63: return "Rain"
        case 65: return "Heavy Rain"
        case 66, 67: return "Freezing Rain"
        case 71: return "Light Snow"
        case 73: return "Snow"
        case 75: return "Heavy Snow"
        case 77: return "Snow Grains"
        case 80, 81, 82: return "Showers"
        case 85, 86: return "Snow Showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Hail Storm"
        default: return "Unknown"
        }
    }

    static func colorFamily(for code: Int) -> String {
        switch code {
        case 0, 1: return "yellow"
        case 2, 3: return "gray"
        case 45, 48: return "gray"
        case 51...57: return "blue"
        case 61...67: return "blue"
        case 71...77: return "cyan"
        case 80...86: return "blue"
        case 95...99: return "purple"
        default: return "gray"
        }
    }
}
