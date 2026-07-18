import SwiftUI

struct ElbowSidebarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingConfig: Bool

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: viewModel.displayedMonth).uppercased()
    }

    private var yearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: viewModel.displayedMonth)
    }

    /// Flavor readout, not a real Star Trek stardate — year + day-of-year, LCARS-style.
    private var stardate: String {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return String(format: "%d.%03d", year, dayOfYear)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: LCARS.Layout.elbowCornerRadius)
                .fill(LCARS.orange)
                .frame(height: 44)
                .overlay(
                    Text("LCARS")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("STARDATE").lcarsLabel(size: 8)
                Text(stardate).lcarsMono(size: 12, color: LCARS.ltblue)
            }

            Rectangle().fill(LCARS.orange.opacity(0.3)).frame(height: LCARS.Layout.hairlineHeight)

            VStack(alignment: .leading, spacing: 6) {
                Text(monthTitle).lcarsHeader(size: 16)
                Text(yearTitle).lcarsMono(size: 11, color: LCARS.orange)
            }

            HStack(spacing: 6) {
                navButton(systemImage: "chevron.left") { viewModel.goToPreviousMonth() }
                navButton(systemImage: "chevron.right") { viewModel.goToNextMonth() }
            }

            Button(action: { viewModel.goToToday() }) {
                Text("TODAY")
                    .lcarsLabel(size: 10, color: .black, opacity: 1)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: LCARS.Layout.badgeCornerRadius).fill(LCARS.tan))
            }
            .buttonStyle(.plain)

            Rectangle().fill(LCARS.orange.opacity(0.3)).frame(height: LCARS.Layout.hairlineHeight)

            VStack(alignment: .leading, spacing: 8) {
                Text("CALENDARS").lcarsLabel(size: 8)
                ForEach(viewModel.sources) { source in
                    HStack(spacing: 6) {
                        Circle().fill(source.color).frame(width: 8, height: 8)
                        Text(source.label.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(LCARS.tan)
                    }
                }
            }

            Rectangle().fill(LCARS.orange.opacity(0.3)).frame(height: LCARS.Layout.hairlineHeight)

            VStack(alignment: .leading, spacing: 6) {
                Text("UPCOMING").lcarsLabel(size: 8)
                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.upcomingEvents(limit: 20)) { event in
                            UpcomingRowView(
                                event: event,
                                color: viewModel.source(for: event.calendarId)?.color ?? LCARS.tan,
                                onJump: { viewModel.jumpToDate(event.start) }
                            )
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)

            Button(action: { showingConfig = true }) {
                Text("CONFIG")
                    .lcarsLabel(size: 10, color: .black, opacity: 1)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: LCARS.Layout.badgeCornerRadius).fill(LCARS.blue))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(LCARS.dark)
    }

    private func navButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: LCARS.Layout.badgeCornerRadius).fill(LCARS.orange))
        }
        .buttonStyle(.plain)
    }
}

private struct UpcomingRowView: View {
    let event: CalendarEvent
    let color: Color
    let onJump: () -> Void

    @State private var isPressed = false

    private var dayTimeLabel: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        let day = dayFormatter.string(from: event.start).uppercased()

        if event.isAllDay { return "\(day) ALL DAY" }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(day) \(timeFormatter.string(from: event.start))"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            Rectangle().fill(color).frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(LCARS.tan)
                    .lineLimit(1)
                Text(dayTimeLabel)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARS.orange.opacity(0.6))
            }
        }
        // Without this, the unconstrained Rectangle accent bar greedily fills
        // whatever height the sidebar's ancestor chain proposes (it stretches
        // to infinity here since ElbowSidebarView is frame(maxHeight: .infinity)),
        // instead of matching the two-line text block beside it.
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 3)
        .padding(.horizontal, 3)
        .background(isPressed ? LCARS.mid : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            onJump()
        })
    }
}
