import Foundation

enum RootStage: Int, Codable, CaseIterable, Comparable {
    case cut = 0
    case callusing = 1
    case rootingStarted = 2
    case rootsGrowing = 3
    case readyToPot = 4

    var label: String {
        switch self {
        case .cut: return "Just Cut"
        case .callusing: return "Callusing"
        case .rootingStarted: return "Roots Starting"
        case .rootsGrowing: return "Roots Growing"
        case .readyToPot: return "Ready to Pot"
        }
    }

    static func < (lhs: RootStage, rhs: RootStage) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A single plant cutting being propagated (water or soil), tracked from
/// initial cut through root development to potting.
struct Cutting: Identifiable, Codable, Equatable {
    let id: UUID
    var plantName: String    // e.g. "Pothos", "Monstera"
    var method: String       // "Water" or "Soil"
    var dateStarted: Date
    var stage: RootStage
    var isPotted: Bool

    init(
        id: UUID = UUID(),
        plantName: String,
        method: String = "Water",
        dateStarted: Date = Date(),
        stage: RootStage = .cut,
        isPotted: Bool = false
    ) {
        self.id = id
        self.plantName = plantName
        self.method = method
        self.dateStarted = dateStarted
        self.stage = stage
        self.isPotted = isPotted
    }

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: dateStarted, to: Date()).day ?? 0
    }
}

/// A dated progress note/photo-less log entry for a cutting (Pro: full
/// history beyond the current stage).
struct RootLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var cuttingID: UUID
    var stage: RootStage
    var date: Date
    var note: String

    init(id: UUID = UUID(), cuttingID: UUID, stage: RootStage, date: Date = Date(), note: String = "") {
        self.id = id
        self.cuttingID = cuttingID
        self.stage = stage
        self.date = date
        self.note = note
    }
}
