import Foundation

/// Raw REST calls against Google Calendar API v3 — deliberately not using the
/// full GTLRCalendarService client library. This app only ever does two
/// read-only GET calls, so a typed REST layer is simpler and avoids pulling
/// in a heavy dependency for a small personal app.
struct GoogleCalendarService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCalendarList(accessToken: String) async throws -> [RemoteCalendarListEntry] {
        var request = URLRequest(
            url: URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList?minAccessRole=reader")!
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        try Self.validate(response, data: data)
        return try JSONDecoder().decode(CalendarListResponse.self, from: data).items
    }

    func fetchEvents(
        calendarId: String,
        accessToken: String,
        timeMin: Date,
        timeMax: Date
    ) async throws -> [CalendarEvent] {
        let encodedId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarId
        var components = URLComponents(
            string: "https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events"
        )!
        components.queryItems = [
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "timeMin", value: Self.instantFormatter.string(from: timeMin)),
            URLQueryItem(name: "timeMax", value: Self.instantFormatter.string(from: timeMax)),
            URLQueryItem(name: "maxResults", value: "250"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        try Self.validate(response, data: data)
        let decoded = try JSONDecoder().decode(EventsResponse.self, from: data)
        return decoded.items.compactMap { $0.toCalendarEvent(calendarId: calendarId) }
    }

    private static func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw GoogleCalendarError.httpError(status: http.statusCode, message: message)
        }
    }

    /// timeMin/timeMax are just instant boundaries for the query window, not
    /// display values, so a plain UTC instant (the ISO8601DateFormatter
    /// default) is fine regardless of the viewer's local time zone.
    private static let instantFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

enum GoogleCalendarError: LocalizedError {
    case httpError(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .httpError(let status, let message):
            return "Google Calendar API error \(status): \(message.prefix(200))"
        }
    }
}

// MARK: - Wire types (Google Calendar API v3 JSON shapes)

struct RemoteCalendarListEntry: Decodable {
    let id: String
    let summary: String?
    let backgroundColor: String?
    let selected: Bool?
    let accessRole: String?
}

private struct CalendarListResponse: Decodable {
    let items: [RemoteCalendarListEntry]
}

private struct RemoteEventDateTime: Decodable {
    let date: String?
    let dateTime: String?

    /// Timed events use `dateTime` (an absolute instant, parsed as-is).
    /// All-day events use `date` (a plain calendar date, e.g. "2026-07-15")
    /// which must be parsed in the LOCAL time zone, not UTC — otherwise a
    /// UTC-midnight instant silently shifts to the previous local day for
    /// anyone west of Greenwich, moving every all-day event back by one day.
    var resolvedDate: Date? {
        if let dateTime {
            return RemoteEventDateTime.fractionalInstantFormatter.date(from: dateTime)
                ?? RemoteEventDateTime.instantFormatter.date(from: dateTime)
        }
        if let date {
            return RemoteEventDateTime.allDayFormatter.date(from: date)
        }
        return nil
    }

    private static let instantFormatter = ISO8601DateFormatter()

    private static let fractionalInstantFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let allDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
}

private struct RemoteEvent: Decodable {
    let id: String
    let summary: String?
    let location: String?
    let status: String?
    let start: RemoteEventDateTime?
    let end: RemoteEventDateTime?

    func toCalendarEvent(calendarId: String) -> CalendarEvent? {
        guard status != "cancelled" else { return nil }
        guard let start, let end,
              let startDate = start.resolvedDate,
              let endDate = end.resolvedDate else { return nil }
        return CalendarEvent(
            id: id,
            calendarId: calendarId,
            title: summary ?? "(No title)",
            start: startDate,
            end: endDate,
            isAllDay: start.date != nil,
            location: location
        )
    }
}

private struct EventsResponse: Decodable {
    let items: [RemoteEvent]
}
