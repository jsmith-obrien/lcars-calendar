import Foundation

struct CalendarEvent: Identifiable, Equatable {
    let id: String              // Google event ID (or mock ID pre-auth)
    let calendarId: String      // which calendar this came from — keys into CalendarSource
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let location: String?
}
