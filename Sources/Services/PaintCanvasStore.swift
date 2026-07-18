import Foundation
import UIKit

/// Backs the shared scribble/notes canvas with a single PNG file on disk, so
/// it survives dismissing the sheet AND relaunching the app entirely — this
/// is meant to be a persistent family note board, not a per-session doodle.
/// Each completed stroke is baked directly into the stored bitmap (real
/// MS-Paint-style behavior: pixels, not an editable/undoable vector layer).
@MainActor
final class PaintCanvasStore: ObservableObject {
    @Published private(set) var image: UIImage?

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("lcars-notepad-canvas.png")
    }

    func load() {
        guard image == nil,
              let data = try? Data(contentsOf: fileURL),
              let loaded = UIImage(data: data) else { return }
        image = loaded
    }

    func bakeStroke(points: [CGPoint], color: UIColor, lineWidth: CGFloat, canvasSize: CGSize) {
        guard canvasSize.width > 0, canvasSize.height > 0, points.count > 1 else { return }

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let baked = renderer.image { context in
            if let existing = image {
                existing.draw(in: CGRect(origin: .zero, size: canvasSize))
            } else {
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: canvasSize))
            }

            let cg = context.cgContext
            cg.setStrokeColor(color.cgColor)
            cg.setLineWidth(lineWidth)
            cg.setLineCap(.round)
            cg.setLineJoin(.round)
            cg.beginPath()
            cg.move(to: points[0])
            for point in points.dropFirst() {
                cg.addLine(to: point)
            }
            cg.strokePath()
        }

        image = baked
        persist()
    }

    func clear(canvasSize: CGSize) {
        guard canvasSize.width > 0, canvasSize.height > 0 else {
            image = nil
            try? FileManager.default.removeItem(at: fileURL)
            return
        }
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
        }
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func persist() {
        guard let image, let data = image.pngData() else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
