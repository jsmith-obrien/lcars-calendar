import SwiftUI

/// Shown when a Google sync attempt fails. This app runs unattended on a
/// wall — a failure needs to be visible at a glance, not buried in a Config
/// screen nobody's actively watching.
struct SignalLostBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(LCARS.red).frame(width: 8, height: 8)
            Text("SIGNAL LOST — \(message.uppercased())")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(LCARS.red)
                .lineLimit(1)
            Spacer()
            Text("SHOWING LAST KNOWN DATA")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(LCARS.red.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(LCARS.red.opacity(0.12))
    }
}
