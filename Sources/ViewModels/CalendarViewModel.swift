import Foundation
import SwiftUI

enum SyncState: Equatable {
    case mock
    case loading
    case live(Date)
    case error(String)
}

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var displayedMonth: Date
    @Published var events: [CalendarEvent] = []
    @Published var sources: [CalendarSource] = [.mockJoshua, .mockSpouse]
    @Published var selectedDay: Date
    @Published var syncState: SyncState = .mock

    private let calendar: Calendar
    private let authService: GoogleAuthService
    private let calendarService: GoogleCalendarService
    private let colorStore: CalendarColorStore

    /// Bumped on every reload; a Google fetch in flight discards its result if
    /// a newer reload started before it finished (e.g. the user tapping next
    /// month repeatedly), so a slow, stale response can never clobber a
    /// fresher one that happened to resolve first.
    private var reloadGeneration = 0

    /// The in-flight reload Task, if any. Cancelling it when a newer reload
    /// starts (rather than just discarding its eventual result via
    /// `reloadGeneration`) actually aborts the in-progress network calls
    /// instead of letting them run to completion and burn API quota for
    /// nothing — important since a wall-mounted device navigating months
    /// quickly would otherwise fire off an unbounded pile of concurrent
    /// requests to Google.
    private var reloadTask: Task<Void, Never>?

    /// Background polling loop (only runs while signed in — mock data never
    /// changes on its own, so there's nothing to poll for when signed out).
    /// A `Task`-based sleep loop rather than `Timer.scheduledTimer`: no
    /// `[weak self]`-vs-strong-capture bookkeeping to get wrong, and
    /// cancelling the Task is the only teardown step needed.
    private var pollingTask: Task<Void, Never>?
    private let pollingInterval: TimeInterval = 600 // 10 minutes

    init(
        calendar: Calendar = .current,
        authService: GoogleAuthService? = nil,
        calendarService: GoogleCalendarService = GoogleCalendarService(),
        colorStore: CalendarColorStore = CalendarColorStore()
    ) {
        // `authService` can't default to `.shared` in the parameter list
        // itself: GoogleAuthService is @MainActor-isolated, and default
        // argument expressions are evaluated in a nonisolated context even
        // though this initializer runs on the MainActor (CalendarViewModel is
        // itself @MainActor) — that mismatch is a warning today and a hard
        // error under Swift 6. Resolving the default inside the init body
        // instead sidesteps it entirely.
        self.calendar = calendar
        self.authService = authService ?? .shared
        self.calendarService = calendarService
        self.colorStore = colorStore
        let today = calendar.startOfDay(for: Date())
        self.displayedMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        self.selectedDay = today
        loadMockEvents()
    }

    // MARK: - Mock data (pre-auth / signed-out fallback)

    func loadMockEvents() {
        events = MockEventProvider.generateEvents(around: displayedMonth, calendar: calendar)
        sources = [.mockJoshua, .mockSpouse]
        syncState = .mock
    }

    // MARK: - Google auth + live data

    /// Called once at launch (see RootView.onAppear). Silently upgrades to
    /// live data if a session is already saved in the keychain; otherwise
    /// leaves the mock data in place so the screen is never blank.
    func restoreSessionIfAvailable() async {
        guard authService.hasPreviousSignIn else { return }
        do {
            try await authService.restorePreviousSignIn()
            await refreshFromGoogle()
            startPolling()
        } catch {
            syncState = .error(error.localizedDescription)
        }
    }

    func signIn() async throws {
        try await authService.signIn()
        await refreshFromGoogle()
        startPolling()
    }

    func signOut() {
        stopPolling()
        authService.signOut()
        loadMockEvents()
    }

    private func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let intervalNanoseconds = self.map({ UInt64($0.pollingInterval * 1_000_000_000) }) else { return }
                try? await Task.sleep(nanoseconds: intervalNanoseconds)
                guard !Task.isCancelled else { return }
                await self?.refreshFromGoogle()
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refreshNow() async {
        if authService.isSignedIn {
            await refreshFromGoogle()
        } else {
            loadMockEvents()
        }
    }

    private func refreshFromGoogle() async {
        reloadGeneration += 1
        let generation = reloadGeneration
        syncState = .loading
        do {
            guard let token = try await authService.freshAccessToken() else {
                syncState = .error("Not signed in")
                return
            }
            guard !Task.isCancelled, generation == reloadGeneration else { return }

            let remoteCalendars = try await calendarService.fetchCalendarList(accessToken: token)
            guard !Task.isCancelled, generation == reloadGeneration else { return }
            let resolvedSources = colorStore.resolve(remoteCalendars: remoteCalendars)

            guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
                guard generation == reloadGeneration else { return }
                syncState = .error("Could not determine month range")
                return
            }
            let timeMin = calendar.date(byAdding: .day, value: -7, to: monthInterval.start) ?? monthInterval.start
            let timeMax = calendar.date(byAdding: .day, value: 7, to: monthInterval.end) ?? monthInterval.end

            var fetchedEvents: [CalendarEvent] = []
            for source in resolvedSources where source.isEnabled {
                guard !Task.isCancelled, generation == reloadGeneration else { return }
                let items = try await calendarService.fetchEvents(
                    calendarId: source.id,
                    accessToken: token,
                    timeMin: timeMin,
                    timeMax: timeMax
                )
                fetchedEvents.append(contentsOf: items)
            }

            guard generation == reloadGeneration else { return }
            sources = resolvedSources
            events = fetchedEvents
            syncState = .live(Date())
        } catch {
            guard generation == reloadGeneration else { return }
            syncState = .error(error.localizedDescription)
        }
    }

    // MARK: - Navigation (mock or live, depending on current auth state)

    private func reload() {
        reloadTask?.cancel()
        reloadTask = Task {
            if authService.isSignedIn {
                await refreshFromGoogle()
            } else {
                loadMockEvents()
            }
        }
    }

    func goToPreviousMonth() {
        guard let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = prev
        reload()
    }

    func goToNextMonth() {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next
        reload()
    }

    func goToToday() {
        let today = calendar.startOfDay(for: Date())
        displayedMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        selectedDay = today
        reload()
    }

    /// Jumps the whole calendar (displayed month + selection) to an arbitrary
    /// date, e.g. from a long-press on an upcoming-events row.
    func jumpToDate(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        displayedMonth = calendar.dateInterval(of: .month, for: day)?.start ?? day
        selectedDay = day
        reload()
    }

    func selectDay(_ day: Date) {
        selectedDay = day
    }

    func isSelected(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: selectedDay)
    }

    func setSourceEnabled(_ id: String, enabled: Bool) {
        guard let index = sources.firstIndex(where: { $0.id == id }) else { return }
        sources[index].isEnabled = enabled
        colorStore.persist(sources)
    }

    func source(for calendarId: String) -> CalendarSource? {
        sources.first { $0.id == calendarId }
    }

    // Matches only an event's start day — a multi-day event (all-day or
    // timed) currently only ever appears on the day it starts, never on
    // subsequent days it spans. Harmless today since nothing in the UI
    // renders multi-day spans, but will need real handling (using `end`,
    // which nothing currently reads) before that changes.
    func events(on day: Date) -> [CalendarEvent] {
        events
            .filter { calendar.isDate($0.start, inSameDayAs: day) }
            .filter { isSourceEnabled($0.calendarId) }
            .sorted { $0.start < $1.start }
    }

    /// Days to render in the month grid, including leading/trailing days from
    /// adjacent months so every week row is fully populated.
    func gridDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingRaw = firstWeekday - calendar.firstWeekday
        let leadingCount = leadingRaw < 0 ? leadingRaw + 7 : leadingRaw
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingCount, to: monthInterval.start) else { return [] }

        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        let totalCells = Int(ceil(Double(leadingCount + daysInMonth) / 7.0)) * 7

        return (0..<totalCells).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    func isInDisplayedMonth(_ day: Date) -> Bool {
        calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
    }

    func isToday(_ day: Date) -> Bool {
        calendar.isDateInToday(day)
    }

    /// Upcoming events from today forward, for the sidebar and day-detail panel.
    func upcomingEvents(limit: Int = 30) -> [CalendarEvent] {
        let today = calendar.startOfDay(for: Date())
        return Array(
            events
                .filter { $0.start >= today }
                .filter { isSourceEnabled($0.calendarId) }
                .sorted { $0.start < $1.start }
                .prefix(limit)
        )
    }

    private func isSourceEnabled(_ calendarId: String) -> Bool {
        sources.first(where: { $0.id == calendarId })?.isEnabled ?? true
    }
}
