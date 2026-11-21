import SwiftUI

@main
struct BrumOrcamentoApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataStore)
        }
    }
}
