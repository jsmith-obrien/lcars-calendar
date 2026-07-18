import Foundation

/// Persists calendarId -> color/label/enabled state across launches, so
/// colors stay stable once assigned instead of reshuffling on every sync.
final class CalendarColorStore {
    private let defaultsKey = "com.lcarscalendar.calendarSources"
    private let palette = ["#FF9900", "#9999FF", "#CC6666", "#99CCFF", "#CC99CC", "#66CCCC"]

    private var stored: [String: CalendarSource] {
        get {
            guard let data = UserDefaults.standard.data(forKey: defaultsKey),
                  let list = try? JSONDecoder().decode([CalendarSource].self, from: data) else {
                return [:]
            }
            return Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        }
        set {
            let list = Array(newValue.values)
            if let data = try? JSONEncoder().encode(list) {
                UserDefaults.standard.set(data, forKey: defaultsKey)
            }
        }
    }

    /// Resolves display metadata for each remote calendar: reuses previously
    /// persisted color/label/enabled state if this calendarId has been seen
    /// before, otherwise seeds from Google's own assigned `backgroundColor`
    /// (falling back to the next unused LCARS palette color) so a fresh
    /// sign-in still looks intentional rather than random.
    func resolve(remoteCalendars: [RemoteCalendarListEntry]) -> [CalendarSource] {
        var known = stored
        var usedColors = Set(known.values.map { $0.colorHex })

        let resolved: [CalendarSource] = remoteCalendars.map { remote in
            if let existing = known[remote.id] {
                var updated = existing
                updated.label = remote.summary ?? existing.label
                return updated
            }
            let colorHex = remote.backgroundColor ?? Self.nextPaletteColor(excluding: usedColors, palette: palette)
            usedColors.insert(colorHex)
            let source = CalendarSource(
                id: remote.id,
                label: remote.summary ?? remote.id,
                colorHex: colorHex,
                isEnabled: remote.selected ?? true
            )
            known[remote.id] = source
            return source
        }

        stored = known
        return resolved
    }

    /// Persists in-app edits (e.g. the config screen's calendar toggles).
    func persist(_ sources: [CalendarSource]) {
        var dict = stored
        for source in sources { dict[source.id] = source }
        stored = dict
    }

    private static func nextPaletteColor(excluding used: Set<String>, palette: [String]) -> String {
        palette.first(where: { !used.contains($0) }) ?? palette[used.count % palette.count]
    }
}
