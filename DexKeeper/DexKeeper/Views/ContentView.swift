import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ListStore

    var body: some View {
        TabView {
            DexBrowserView()
                .tabItem { Label("Dex", systemImage: "books.vertical.fill") }

            ListsView()
                .tabItem { Label("Lists", systemImage: "list.bullet.rectangle.portrait.fill") }
                .badge(store.activeList.pokemon.count)

            CoverageAnalysisView()
                .tabItem { Label("Battle Prep", systemImage: "shield.lefthalf.filled") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ListStore())
}
