import SwiftUI

struct MonthGridView: View {
    @ObservedObject var viewModel: CalendarViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    private let minRowHeight: CGFloat = 70

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .lcarsLabel(size: 9)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 10)

            GeometryReader { geometry in
                let days = viewModel.gridDays()
                let rowCount = max(days.count / 7, 1)
                let rowSpacing: CGFloat = 4
                let availableHeight = geometry.size.height - (CGFloat(rowCount - 1) * rowSpacing)
                let rowHeight = max(availableHeight / CGFloat(rowCount), minRowHeight)

                LazyVGrid(columns: columns, spacing: rowSpacing) {
                    ForEach(days, id: \.self) { day in
                        DayCellView(
                            day: day,
                            isInMonth: viewModel.isInDisplayedMonth(day),
                            isToday: viewModel.isToday(day),
                            isSelected: viewModel.isSelected(day),
                            events: viewModel.events(on: day),
                            colorFor: { calendarId in viewModel.source(for: calendarId)?.color ?? LCARS.tan }
                        )
                        .frame(height: rowHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectDay(day)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .background(LCARS.black)
    }
}

private struct DayCellView: View {
    let day: Date
    let isInMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let events: [CalendarEvent]
    let colorFor: (String) -> Color

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(dayNumber)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(isInMonth ? LCARS.tan : LCARS.tan.opacity(0.4))

            VStack(alignment: .leading, spacing: 3) {
                ForEach(events.prefix(3)) { event in
                    Text(event.title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorFor(event.calendarId).opacity(isInMonth ? 1 : 0.4))
                        .cornerRadius(2)
                }
                if events.count > 3 {
                    Text("+\(events.count - 3) MORE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(LCARS.orange.opacity(0.7))
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(isSelected ? LCARS.blue.opacity(0.3) : LCARS.dark)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isToday ? LCARS.orange : Color.clear, lineWidth: 2)
        )
        .cornerRadius(4)
    }
}
