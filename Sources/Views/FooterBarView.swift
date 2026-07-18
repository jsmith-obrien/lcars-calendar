import SwiftUI

struct FooterBarView: View {
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4).fill(LCARS.pink.opacity(0.4))
            RoundedRectangle(cornerRadius: 4).fill(LCARS.purple.opacity(0.4)).frame(width: 50)
            RoundedRectangle(cornerRadius: 4).fill(LCARS.blue.opacity(0.4)).frame(width: 70)
        }
        .frame(height: LCARS.Layout.footerBarHeight)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(LCARS.black)
    }
}
