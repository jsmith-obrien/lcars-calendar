import SwiftUI

/// Fifth screen — a very simplistic MS-Paint-style scratchpad for scribbling
/// notes or quick pictures to each other. Persistent by design (see
/// PaintCanvasStore): the canvas survives closing this sheet and relaunching
/// the app, and only goes blank when Clear is explicitly tapped.
struct PaintView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = PaintCanvasStore()
    @State private var currentStrokePoints: [CGPoint] = []
    @State private var selectedColor: Color = .black
    @State private var canvasSize: CGSize = .zero

    private let palette: [Color] = [.black, LCARS.orange, LCARS.red, LCARS.blue, LCARS.green, LCARS.purple]
    private let lineWidth: CGFloat = 5

    var body: some View {
        VStack(spacing: 0) {
            header

            Rectangle()
                .fill(LCARS.orange)
                .frame(height: LCARS.Layout.dividerHeight)
                .padding(.horizontal, 8)

            canvasArea

            colorPalette

            FooterBarView()
        }
        .background(LCARS.black.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: LCARS.Layout.elbowCornerRadius)
                .fill(LCARS.orange)
                .frame(width: 70, height: 36)
                .overlay(Text("LCARS").font(.system(size: 12, weight: .bold)).foregroundColor(.black))

            VStack(alignment: .leading, spacing: 1) {
                Text("NOTEPAD").lcarsHeader(size: 15)
                Text("SHARED SCRATCHPAD").font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARS.orange.opacity(0.5))
            }

            Spacer()

            Button(action: { store.clear(canvasSize: canvasSize) }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LCARS.orange))
            }
            .buttonStyle(.plain)

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LCARS.red))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(LCARS.dark)
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        GeometryReader { geo in
            ZStack {
                Color.white

                if let image = store.image {
                    Image(uiImage: image)
                        .resizable()
                }

                Canvas { context, _ in
                    guard currentStrokePoints.count > 1 else { return }
                    var path = Path()
                    path.addLines(currentStrokePoints)
                    context.stroke(
                        path,
                        with: .color(selectedColor),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentStrokePoints.append(value.location)
                    }
                    .onEnded { _ in
                        store.bakeStroke(
                            points: currentStrokePoints,
                            color: UIColor(selectedColor),
                            lineWidth: lineWidth,
                            canvasSize: geo.size
                        )
                        currentStrokePoints = []
                    }
            )
            .onAppear {
                canvasSize = geo.size
                store.load()
            }
        }
    }

    // MARK: - Color palette

    private var colorPalette: some View {
        HStack(spacing: 14) {
            ForEach(Array(palette.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle().stroke(LCARS.tan, lineWidth: colorsMatch(selectedColor, color) ? 3 : 0)
                    )
                    .onTapGesture { selectedColor = color }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(LCARS.dark)
    }

    private func colorsMatch(_ a: Color, _ b: Color) -> Bool {
        UIColor(a) == UIColor(b)
    }
}
