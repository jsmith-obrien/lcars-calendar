import SwiftUI

struct DayDetailPanel: View {
    @ObservedObject var viewModel: CalendarViewModel

    private var selectedDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: viewModel.selectedDay).uppercased()
    }

    private var selectedEvents: [CalendarEvent] {
        viewModel.events(on: viewModel.selectedDay)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedDateLabel)
                .lcarsHeader(size: 13)
                .padding(.horizontal, 10)
                .padding(.top, 8)

            Rectangle().fill(LCARS.orange.opacity(0.3)).frame(height: LCARS.Layout.hairlineHeight)
                .padding(.horizontal, 10)

            if selectedEvents.isEmpty {
                Text("NO EVENTS")
                    .lcarsLabel(size: 9)
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                Spacer(minLength: 0)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedEvents) { event in
                            EventChipView(
                                event: event,
                                color: viewModel.source(for: event.calendarId)?.color ?? LCARS.tan
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(height: 96)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LCARS.dark)
    }
}

private struct EventChipView: View {
    let event: CalendarEvent
    let color: Color

    private var timeLabel: String {
        if event.isAllDay { return "ALL DAY" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.start)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Rectangle().fill(color).frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(LCARS.tan)
                    .lineLimit(1)
                Text(timeLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARS.orange.opacity(0.6))
                if let location = event.location {
                    Text(location.uppercased())
                        .font(.system(size: 8))
                        .foregroundColor(LCARS.tan.opacity(0.4))
                        .lineLimit(1)
                }
            }
        }
        .padding(6)
        .frame(minWidth: 120, alignment: .topLeading)
        .background(LCARS.mid)
        .cornerRadius(4)
    }
}
