import Foundation

/// Deterministic mock event generator for the static-shell phase (no Google auth yet).
/// Produces a sparse, plausible-looking family calendar rather than a dense test grid.
enum MockEventProvider {
    static func generateEvents(around referenceDate: Date, calendar: Calendar = .current) -> [CalendarEvent] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: referenceDate),
              let windowStart = calendar.date(byAdding: .day, value: -7, to: monthInterval.start),
              let windowEnd = calendar.date(byAdding: .day, value: 7, to: monthInterval.end) else {
            return []
        }

        var events: [CalendarEvent] = []
        var day = windowStart
        var index = 0
        while day < windowEnd {
            defer { day = calendar.date(byAdding: .day, value: 1, to: day) ?? windowEnd }
            index += 1

            if index % 5 == 0 {
                events.append(CalendarEvent(
                    id: "mock-\(index)-standup",
                    calendarId: CalendarSource.mockJoshua.id,
                    title: "Standup",
                    start: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day,
                    end: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: day) ?? day,
                    isAllDay: false,
                    location: nil
                ))
            }
            if index % 7 == 3 {
                events.append(CalendarEvent(
                    id: "mock-\(index)-yoga",
                    calendarId: CalendarSource.mockSpouse.id,
                    title: "Yoga",
                    start: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day,
                    end: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: day) ?? day,
                    isAllDay: false,
                    location: "Studio"
                ))
            }
            if index % 11 == 0 {
                events.append(CalendarEvent(
                    id: "mock-\(index)-dentist",
                    calendarId: CalendarSource.mockJoshua.id,
                    title: "Dentist",
                    start: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: day) ?? day,
                    end: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: day) ?? day,
                    isAllDay: false,
                    location: "Dr. Chen"
                ))
            }
            if index % 13 == 0 {
                let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
                events.append(CalendarEvent(
                    id: "mock-\(index)-bookclub",
                    calendarId: CalendarSource.mockSpouse.id,
                    title: "Book Club",
                    start: day,
                    end: nextDay,
                    isAllDay: true,
                    location: nil
                ))
            }
            if index % 17 == 0 {
                events.append(CalendarEvent(
                    id: "mock-\(index)-datenight",
                    calendarId: CalendarSource.mockJoshua.id,
                    title: "Date Night",
                    start: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: day) ?? day,
                    end: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: day) ?? day,
                    isAllDay: false,
                    location: "Downtown"
                ))
            }
        }
        return events
    }
}
