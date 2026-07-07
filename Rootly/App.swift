import SwiftUI

@main
struct RootlyApp: App {
    @StateObject private var store = RootlyStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
