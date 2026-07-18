import SwiftUI

struct HeaderBarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingWeather: Bool
    @Binding var showingGame: Bool
    @Binding var showingNotepad: Bool

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.displayedMonth).uppercased()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: LCARS.Layout.elbowCornerRadius)
                    .fill(LCARS.orange)
                    .frame(width: 70, height: 36)
                    .overlay(Text("LCARS").font(.system(size: 12, weight: .bold)).foregroundColor(.black))

                VStack(alignment: .leading, spacing: 1) {
                    Text("FAMILY CALENDAR").lcarsHeader(size: 15)
                    Text(monthYearTitle)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(LCARS.orange.opacity(0.5))
                }

                Spacer()

                Button(action: { showingWeather = true }) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(LCARS.ltblue))
                }
                .buttonStyle(.plain)

                Button(action: { showingGame = true }) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(LCARS.purple))
                }
                .buttonStyle(.plain)

                Button(action: { showingNotepad = true }) {
                    Image(systemName: "pencil.and.scribble")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(LCARS.pink))
                }
                .buttonStyle(.plain)

                statusPill
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(LCARS.dark)

            Rectangle()
                .fill(LCARS.orange)
                .frame(height: LCARS.Layout.dividerHeight)
                .padding(.horizontal, 8)
        }
    }

    private var statusPill: some View {
        Text(statusText)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(statusColor))
    }

    private var statusText: String {
        switch viewModel.syncState {
        case .mock: return "MOCK DATA"
        case .loading: return "SYNCING..."
        case .live(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "SYNCED \(formatter.string(from: date))"
        case .error: return "SYNC ERROR"
        }
    }

    private var statusColor: Color {
        switch viewModel.syncState {
        case .mock: return LCARS.ltblue
        case .loading: return LCARS.blue
        case .live: return LCARS.green
        case .error: return LCARS.red
        }
    }
}
