import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingConfig = false
    @State private var showingWeather = false
    @State private var showingGame = false
    @State private var showingNotepad = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        HStack(spacing: 0) {
            ElbowSidebarView(viewModel: viewModel, showingConfig: $showingConfig)
                .frame(width: LCARS.Layout.sidebarWidth)

            VStack(spacing: 0) {
                HeaderBarView(viewModel: viewModel, showingWeather: $showingWeather, showingGame: $showingGame, showingNotepad: $showingNotepad)

                if case .error(let message) = viewModel.syncState {
                    SignalLostBanner(message: message)
                }

                HStack(spacing: 0) {
                    MonthGridView(viewModel: viewModel)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LCARS.orange.opacity(0.5))
                        .frame(width: 10)
                        .padding(.vertical, 10)
                }

                DayDetailPanel(viewModel: viewModel)

                FooterBarView()
            }
        }
        .background(LCARS.black.ignoresSafeArea())
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            OrientationLock.shared.applyImmediately()
            KioskModeStore.shared.requestSessionIfEnabled()
            Task { await viewModel.restoreSessionIfAvailable() }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                KioskModeStore.shared.requestSessionIfEnabled()
                Task { await viewModel.refreshNow() }
            }
        }
        .sheet(isPresented: $showingConfig) {
            ConfigView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingWeather) {
            WeatherView()
        }
        .sheet(isPresented: $showingGame) {
            TicTacToeView()
        }
        .sheet(isPresented: $showingNotepad) {
            PaintView()
        }
    }
}
