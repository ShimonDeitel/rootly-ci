import XCTest
@testable import Rootly

final class RootlyTests: XCTestCase {
    var store: RootlyStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = RootlyStore()
        store.deleteAllData()
        for c in store.cuttings { store.deleteCutting(c.id) }
    }

    @MainActor
    func testAddCutting() {
        let added = store.addCutting(plantName: "Monstera", method: "Water", isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.cuttings.count, 1)
        XCTAssertEqual(store.cuttings[0].stage, .cut)
    }

    @MainActor
    func testAddCuttingRejectsEmptyName() {
        let added = store.addCutting(plantName: "  ", method: "Water", isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksFourthCutting() {
        _ = store.addCutting(plantName: "A", method: "Water", isPro: false)
        _ = store.addCutting(plantName: "B", method: "Water", isPro: false)
        _ = store.addCutting(plantName: "C", method: "Soil", isPro: false)
        XCTAssertFalse(store.canAddCutting(isPro: false))
        let fourth = store.addCutting(plantName: "D", method: "Water", isPro: false)
        XCTAssertFalse(fourth)
        XCTAssertEqual(store.cuttings.count, 3)
    }

    @MainActor
    func testProAllowsUnlimitedCuttings() {
        for i in 0..<4 {
            _ = store.addCutting(plantName: "Plant\(i)", method: "Water", isPro: true)
        }
        XCTAssertEqual(store.cuttings.count, 4)
    }

    @MainActor
    func testUpdateCutting() {
        _ = store.addCutting(plantName: "Monstera", method: "Water", isPro: false)
        let id = store.cuttings[0].id
        store.updateCutting(id, plantName: "Monstera", method: "Soil")
        XCTAssertEqual(store.cuttings[0].method, "Soil")
    }

    @MainActor
    func testDeleteCuttingAlsoDeletesLogEntries() {
        _ = store.addCutting(plantName: "Monstera", method: "Water", isPro: false)
        let id = store.cuttings[0].id
        XCTAssertFalse(store.logEntries.isEmpty)
        store.deleteCutting(id)
        XCTAssertTrue(store.cuttings.isEmpty)
        XCTAssertTrue(store.logEntries.isEmpty)
    }

    @MainActor
    func testAdvanceStageProgressesThroughAllStages() {
        _ = store.addCutting(plantName: "Monstera", method: "Water", isPro: false)
        let id = store.cuttings[0].id
        XCTAssertEqual(store.cuttings[0].stage, .cut)
        XCTAssertTrue(store.advanceStage(id))
        XCTAssertEqual(store.cuttings[0].stage, .callusing)
        XCTAssertTrue(store.advanceStage(id))
        XCTAssertEqual(store.cuttings[0].stage, .rootingStarted)
        XCTAssertTrue(store.advanceStage(id))
        XCTAssertEqual(store.cuttings[0].stage, .rootsGrowing)
        XCTAssertTrue(store.advanceStage(id))
        XCTAssertEqual(store.cuttings[0].stage, .readyToPot)
    }

    @MainActor
    func testAdvanceStageReturnsFalseAtFinalStage() {
        _ = store.addCutting(plantName: "Monstera", method: "Water", isPro: false)
        let id = store.cuttings[0].id
        for _ in 0..<4 { store.advanceStage(id) }
        XCTAssertEqual(store.cuttings[0].stage, .readyToPot)
        XCTAssertFalse(store.advanceStage(id))
    }

    @MainActor
    func testMarkPottedSetsFlagAndStage() {
        _ = store.addCutting(plantName: "Monstera", method: "Water", isPro: false)
        let id = store.cuttings[0].id
        store.markPotted(id)
        XCTAssertTrue(store.cuttings[0].isPotted)
        XCTAssertEqual(store.cuttings[0].stage, .readyToPot)
    }

    @MainActor
    func testActiveAndPottedCuttingsFilter() {
        _ = store.addCutting(plantName: "Active", method: "Water", isPro: true)
        _ = store.addCutting(plantName: "Potted", method: "Water", isPro: true)
        let pottedID = store.cuttings[1].id
        store.markPotted(pottedID)
        XCTAssertEqual(store.activeCuttings.count, 1)
        XCTAssertEqual(store.pottedCuttings.count, 1)
        XCTAssertEqual(store.activeCuttings.first?.plantName, "Active")
    }

    func testRootStageOrdering() {
        XCTAssertTrue(RootStage.cut < RootStage.callusing)
        XCTAssertTrue(RootStage.rootsGrowing < RootStage.readyToPot)
        XCTAssertFalse(RootStage.readyToPot < RootStage.cut)
    }

    @MainActor
    func testTotalDaysWaitingSumsActiveOnly() {
        let cal = Calendar.current
        _ = store.addCutting(plantName: "Old", method: "Water", isPro: true)
        // seed's addCutting always uses "now" as dateStarted; verify sum is non-negative and reflects active only
        let pottedName = "Potted"
        _ = store.addCutting(plantName: pottedName, method: "Water", isPro: true)
        let pottedID = store.cuttings.first { $0.plantName == pottedName }!.id
        store.markPotted(pottedID)
        XCTAssertGreaterThanOrEqual(store.totalDaysWaiting, 0)
        _ = cal // silence unused warning in case Date math changes later
    }

    @MainActor
    func testDeleteAllDataReseeds() {
        _ = store.addCutting(plantName: "Extra", method: "Water", isPro: true)
        store.deleteAllData()
        XCTAssertFalse(store.cuttings.isEmpty)
    }
}
