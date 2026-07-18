import SwiftUI

private enum Player: String {
    case x = "X"
    case o = "O"

    var color: Color {
        switch self {
        case .x: return LCARS.orange
        case .o: return LCARS.ltblue
        }
    }

    var opposite: Player {
        self == .x ? .o : .x
    }
}

private enum GameResult: Equatable {
    case inProgress
    case win(Player, line: [Int])
    case draw
}

/// Fourth screen (calendar / config / weather / tic-tac-toe), reached via
/// the grid icon in HeaderBarView. Close button is top-LEFT here (unlike
/// Config/Weather's top-right X) per explicit request.
struct TicTacToeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var board: [Player?] = Array(repeating: nil, count: 9)
    @State private var currentPlayer: Player = .x

    private static let winningLines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
        [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
        [0, 4, 8], [2, 4, 6],            // diagonals
    ]

    private var result: GameResult {
        for line in Self.winningLines {
            if let first = board[line[0]], board[line[1]] == first, board[line[2]] == first {
                return .win(first, line: line)
            }
        }
        if board.allSatisfy({ $0 != nil }) {
            return .draw
        }
        return .inProgress
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Rectangle()
                .fill(LCARS.orange)
                .frame(height: LCARS.Layout.dividerHeight)
                .padding(.horizontal, 8)

            boardView

            FooterBarView()
        }
        .background(LCARS.black.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LCARS.red))
            }
            .buttonStyle(.plain)

            RoundedRectangle(cornerRadius: LCARS.Layout.elbowCornerRadius)
                .fill(LCARS.orange)
                .frame(width: 70, height: 36)
                .overlay(Text("LCARS").font(.system(size: 12, weight: .bold)).foregroundColor(.black))

            VStack(alignment: .leading, spacing: 1) {
                Text("TIC-TAC-TOE").lcarsHeader(size: 15)
                Text("STRATEGIC GRID SIMULATION")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARS.orange.opacity(0.5))
            }

            Spacer()

            statusPill

            Button(action: reset) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LCARS.blue))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(LCARS.dark)
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
        switch result {
        case .inProgress: return "\(currentPlayer.rawValue)'S TURN"
        case .win(let player, _): return "\(player.rawValue) WINS"
        case .draw: return "DRAW"
        }
    }

    private var statusColor: Color {
        switch result {
        case .inProgress: return currentPlayer.color
        case .win(let player, _): return player.color
        case .draw: return LCARS.tan
        }
    }

    // MARK: - Board

    private var boardView: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 14
            let available = min(geo.size.width, geo.size.height) - 40
            let cellSize = (available - spacing * 2) / 3

            VStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<3, id: \.self) { col in
                            cellView(index: row * 3 + col, size: cellSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(20)
    }

    private func cellView(index: Int, size: CGFloat) -> some View {
        let isWinningCell: Bool = {
            if case .win(_, let line) = result { return line.contains(index) }
            return false
        }()

        return Button(action: { place(at: index) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LCARS.dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isWinningCell ? LCARS.green : LCARS.orange.opacity(0.3), lineWidth: isWinningCell ? 4 : 2)
                    )

                if let mark = board[index] {
                    Text(mark.rawValue)
                        .font(.system(size: size * 0.5, weight: .bold, design: .monospaced))
                        .foregroundColor(mark.color)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .disabled(board[index] != nil || result != .inProgress)
    }

    // MARK: - Game logic

    private func place(at index: Int) {
        guard board[index] == nil, result == .inProgress else { return }
        board[index] = currentPlayer
        currentPlayer = currentPlayer.opposite
    }

    private func reset() {
        board = Array(repeating: nil, count: 9)
        currentPlayer = .x
    }
}
