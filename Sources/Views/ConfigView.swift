import SwiftUI

struct ConfigView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @ObservedObject private var orientationLock = OrientationLock.shared
    @ObservedObject private var kioskMode = KioskModeStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var authErrorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(OrientationPreference.allCases) { option in
                        Button(action: { orientationLock.preference = option; orientationLock.applyImmediately() }) {
                            HStack {
                                Text(option.label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(LCARS.tan)
                                Spacer()
                                if orientationLock.preference == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(LCARS.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(LCARS.dark)
                } header: {
                    Text("Orientation").foregroundColor(LCARS.orange.opacity(0.7))
                } footer: {
                    Text("Switch this when the iPad moves to a different spot on the fridge and the cable needs to come out the other side. Takes effect immediately.")
                        .font(.system(size: 10))
                        .foregroundColor(LCARS.tan.opacity(0.4))
                }

                Section {
                    HStack {
                        Text("Auto Guided Access").foregroundColor(LCARS.tan)
                        Spacer()
                        Toggle("", isOn: $kioskMode.isEnabled)
                            .labelsHidden()
                            .tint(LCARS.orange)
                    }
                    .listRowBackground(LCARS.dark)
                } header: {
                    Text("Kiosk Mode").foregroundColor(LCARS.orange.opacity(0.7))
                } footer: {
                    Text("When on, the app asks the system to start Guided Access every time it opens — no more manual triple-click. Requires Guided Access to be turned on once in Settings > Accessibility > Guided Access. To turn this back off, exit Guided Access first (triple-click, then Face ID or your Guided Access passcode).")
                        .font(.system(size: 10))
                        .foregroundColor(LCARS.tan.opacity(0.4))
                }

                Section {
                    ForEach(viewModel.sources) { source in
                        HStack {
                            Circle().fill(source.color).frame(width: 10, height: 10)
                            Text(source.label.uppercased())
                                .foregroundColor(LCARS.tan)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { source.isEnabled },
                                set: { viewModel.setSourceEnabled(source.id, enabled: $0) }
                            ))
                            .labelsHidden()
                            .tint(LCARS.orange)
                        }
                    }
                    .listRowBackground(LCARS.dark)
                } header: {
                    Text("Calendars").foregroundColor(LCARS.orange.opacity(0.7))
                }

                Section {
                    HStack {
                        Text("Google Account").foregroundColor(LCARS.tan)
                        Spacer()
                        Text(accountStatusText)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(accountStatusColor)
                    }
                    .listRowBackground(LCARS.dark)

                    Button(action: handleAccountButtonTap) {
                        Text(accountButtonTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: LCARS.Layout.badgeCornerRadius).fill(LCARS.orange))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningIn)
                    .listRowBackground(LCARS.dark)

                    if let authErrorMessage {
                        Text(authErrorMessage)
                            .font(.system(size: 10))
                            .foregroundColor(LCARS.red)
                            .listRowBackground(LCARS.dark)
                    }
                } header: {
                    Text("Account").foregroundColor(LCARS.orange.opacity(0.7))
                }

                Section {
                    HStack {
                        Text("Status").foregroundColor(LCARS.tan)
                        Spacer()
                        Text(syncStatusText)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(syncStatusColor)
                    }
                    .listRowBackground(LCARS.dark)

                    Button(action: { Task { await viewModel.refreshNow() } }) {
                        Text("REFRESH NOW")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: LCARS.Layout.badgeCornerRadius).fill(LCARS.blue))
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(LCARS.dark)

                    Text("Auto-refreshes every 10 minutes while signed in, plus whenever the app returns to the foreground, on top of the manual triggers above.")
                        .font(.system(size: 10))
                        .foregroundColor(LCARS.tan.opacity(0.5))
                        .listRowBackground(LCARS.dark)
                } header: {
                    Text("Sync").foregroundColor(LCARS.orange.opacity(0.7))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("CONFIGURATION")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .background(LCARS.black.ignoresSafeArea())
    }

    private var accountStatusText: String {
        GoogleAuthService.shared.isSignedIn ? (GoogleAuthService.shared.currentUserEmail ?? "SIGNED IN") : "NOT CONNECTED"
    }

    private var accountStatusColor: Color {
        GoogleAuthService.shared.isSignedIn ? LCARS.green : LCARS.red
    }

    private var accountButtonTitle: String {
        if isSigningIn { return "SIGNING IN..." }
        return GoogleAuthService.shared.isSignedIn ? "SIGN OUT" : "SIGN IN WITH GOOGLE"
    }

    private func handleAccountButtonTap() {
        if GoogleAuthService.shared.isSignedIn {
            authErrorMessage = nil
            viewModel.signOut()
            return
        }
        authErrorMessage = nil
        isSigningIn = true
        Task {
            do {
                try await viewModel.signIn()
            } catch {
                authErrorMessage = error.localizedDescription
            }
            isSigningIn = false
        }
    }

    private var syncStatusText: String {
        switch viewModel.syncState {
        case .mock: return "MOCK DATA"
        case .loading: return "SYNCING..."
        case .live(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "SYNCED \(formatter.string(from: date))"
        case .error(let message):
            return "ERROR: \(message.prefix(60))"
        }
    }

    private var syncStatusColor: Color {
        switch viewModel.syncState {
        case .mock: return LCARS.ltblue
        case .loading: return LCARS.blue
        case .live: return LCARS.green
        case .error: return LCARS.red
        }
    }
}
