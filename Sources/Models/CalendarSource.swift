import SwiftUI

/// Display metadata for a calendar (person/household), keyed by Google calendarId.
/// Kept separate from CalendarEvent so color/label edits in the config screen
/// don't require touching event data, and so this can be persisted independently.
struct CalendarSource: Identifiable, Codable, Equatable {
    let id: String          // Google calendarId (or "mock-joshua" / "mock-spouse" pre-auth)
    var label: String
    var colorHex: String
    var isEnabled: Bool

    var color: Color { Color(hex: colorHex) }

    static let mockJoshua = CalendarSource(id: "mock-joshua", label: "Joshua", colorHex: "#FF9900", isEnabled: true)
    static let mockSpouse = CalendarSource(id: "mock-spouse", label: "Spouse", colorHex: "#9999FF", isEnabled: true)
}
