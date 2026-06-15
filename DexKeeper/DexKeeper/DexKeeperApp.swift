import SwiftUI

@main
struct DexKeeperApp: App {
    @StateObject private var store = ListStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
