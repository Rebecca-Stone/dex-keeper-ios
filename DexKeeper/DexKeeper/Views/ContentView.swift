import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TeamStore

    var body: some View {
        TabView {
            DexBrowserView()
                .tabItem { Label("Dex", systemImage: "books.vertical.fill") }

            TeamView()
                .tabItem { Label("Team", systemImage: "person.3.fill") }
                .badge(store.team.members.count)

            CoverageAnalysisView()
                .tabItem { Label("Battle Prep", systemImage: "shield.lefthalf.filled") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TeamStore())
}
