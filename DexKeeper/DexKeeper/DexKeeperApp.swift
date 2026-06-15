import SwiftUI

@main
struct DexKeeperApp: App {
    @StateObject private var api = PokeAPIService.shared
    @StateObject private var store = TeamStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(api)
                .environmentObject(store)
        }
    }
}
