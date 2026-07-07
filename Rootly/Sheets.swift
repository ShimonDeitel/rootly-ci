import SwiftUI

enum RootlySheet: Identifiable {
    case addCutting
    case editCutting(Cutting)
    case paywall

    var id: String {
        switch self {
        case .addCutting: return "addCutting"
        case .editCutting(let c): return "edit-\(c.id)"
        case .paywall: return "paywall"
        }
    }
}

struct CuttingFormView: View {
    @EnvironmentObject private var store: RootlyStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: Cutting?

    @State private var plantName: String
    @State private var method: String

    init(existing: Cutting?) {
        self.existing = existing
        _plantName = State(initialValue: existing?.plantName ?? "")
        _method = State(initialValue: existing?.method ?? "Water")
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cutting") {
                    TextField("Plant name (e.g. Pothos)", text: $plantName)
                        .accessibilityIdentifier("plantNameField")

                    Picker("Method", selection: $method) {
                        Text("Water").tag("Water")
                        Text("Soil").tag("Soil")
                    }
                    .accessibilityIdentifier("methodPicker")
                }

                if isEditing {
                    Section {
                        Button("Delete Cutting", role: .destructive) {
                            if let existing {
                                store.deleteCutting(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteCuttingButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Cutting" : "New Cutting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if isEditing, let existing {
                            store.updateCutting(existing.id, plantName: plantName, method: method)
                        } else {
                            store.addCutting(plantName: plantName, method: method, isPro: purchases.isPro)
                        }
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(plantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("saveCuttingButton")
                }
            }
        }
    }
}
