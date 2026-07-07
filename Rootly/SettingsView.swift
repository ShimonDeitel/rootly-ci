import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: RootlyStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("rootly_water_reminders") private var waterReminders: Bool = true
    @AppStorage("rootly_reminder_days") private var reminderDays: Int = 3
    @State private var activeSheet: RootlySheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Water Change Reminders") {
                    Toggle("Remind me to change water", isOn: $waterReminders)
                        .accessibilityIdentifier("waterRemindersToggle")

                    if waterReminders {
                        Stepper("Every \(reminderDays) day(s)", value: $reminderDays, in: 1...14)
                            .accessibilityIdentifier("reminderDaysStepper")
                    }
                }

                Section("Rootly Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(RLTheme.moss)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(RLTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/rootly-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(RLTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .dismissKeyboardOnTap()
            .confirmationDialog(
                "Reset all cuttings and history?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(RootlyStore())
        .environmentObject(PurchaseManager())
}
