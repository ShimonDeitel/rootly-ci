import Foundation
import Combine

@MainActor
final class RootlyStore: ObservableObject {
    @Published private(set) var cuttings: [Cutting] = []
    @Published private(set) var logEntries: [RootLogEntry] = []

    static let freeCuttingLimit = 3

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("rootly_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if cuttings.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let cal = Calendar.current
        let pothos = Cutting(
            plantName: "Pothos",
            method: "Water",
            dateStarted: cal.date(byAdding: .day, value: -14, to: Date())!,
            stage: .rootingStarted
        )
        cuttings = [pothos]
        logEntries = [
            RootLogEntry(cuttingID: pothos.id, stage: .cut, date: cal.date(byAdding: .day, value: -14, to: Date())!),
            RootLogEntry(cuttingID: pothos.id, stage: .callusing, date: cal.date(byAdding: .day, value: -9, to: Date())!),
            RootLogEntry(cuttingID: pothos.id, stage: .rootingStarted, date: Date())
        ]
        save()
    }

    func canAddCutting(isPro: Bool) -> Bool {
        isPro || cuttings.count < Self.freeCuttingLimit
    }

    @discardableResult
    func addCutting(plantName: String, method: String, isPro: Bool) -> Bool {
        let trimmed = plantName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddCutting(isPro: isPro) else { return false }
        let cutting = Cutting(plantName: trimmed, method: method)
        cuttings.append(cutting)
        logEntries.append(RootLogEntry(cuttingID: cutting.id, stage: .cut))
        save()
        return true
    }

    func updateCutting(_ id: UUID, plantName: String, method: String) {
        let trimmed = plantName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = cuttings.firstIndex(where: { $0.id == id }) else { return }
        cuttings[idx].plantName = trimmed
        cuttings[idx].method = method
        save()
    }

    func deleteCutting(_ id: UUID) {
        cuttings.removeAll { $0.id == id }
        logEntries.removeAll { $0.cuttingID == id }
        save()
    }

    /// Advance a cutting to the next root stage, logging the transition.
    /// Returns false if already at the final stage.
    @discardableResult
    func advanceStage(_ id: UUID, note: String = "") -> Bool {
        guard let idx = cuttings.firstIndex(where: { $0.id == id }) else { return false }
        let current = cuttings[idx].stage
        guard let next = RootStage(rawValue: current.rawValue + 1) else { return false }
        cuttings[idx].stage = next
        logEntries.append(RootLogEntry(cuttingID: id, stage: next, note: note))
        save()
        return true
    }

    func markPotted(_ id: UUID) {
        guard let idx = cuttings.firstIndex(where: { $0.id == id }) else { return }
        cuttings[idx].isPotted = true
        if cuttings[idx].stage != .readyToPot {
            cuttings[idx].stage = .readyToPot
        }
        save()
    }

    func deleteAllData() {
        cuttings = []
        logEntries = []
        seedDefaults()
    }

    // MARK: - Derived

    func logEntries(for cuttingID: UUID) -> [RootLogEntry] {
        logEntries.filter { $0.cuttingID == cuttingID }.sorted { $0.date < $1.date }
    }

    var activeCuttings: [Cutting] {
        cuttings.filter { !$0.isPotted }
    }

    var pottedCuttings: [Cutting] {
        cuttings.filter(\.isPotted)
    }

    /// Quirky signature stat: total days of root-growing patience across
    /// all active cuttings — a "greenhouse patience" tally.
    var totalDaysWaiting: Int {
        activeCuttings.reduce(0) { $0 + $1.daysSinceStart }
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var cuttings: [Cutting]
        var logEntries: [RootLogEntry]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            cuttings = decoded.cuttings
            logEntries = decoded.logEntries
        }
    }

    func save() {
        let snapshot = Snapshot(cuttings: cuttings, logEntries: logEntries)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
