import SwiftUI

struct ListsView: View {
    @EnvironmentObject private var store: ListStore
    @State private var showingNew = false
    @State private var newName = ""
    @State private var newIsTeam = true

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.lists) { list in
                    NavigationLink(value: list.id) {
                        listRow(list)
                    }
                }
                .onDelete(perform: deleteLists)
            }
            .navigationTitle("Lists")
            .navigationDestination(for: UUID.self) { id in
                RosterView(listID: id)
            }
            .navigationDestination(for: Species.self) { species in
                PokemonDetailView(species: species)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startNewList() } label: { Image(systemName: "plus") }
                }
            }
            .alert("New List", isPresented: $showingNew) {
                TextField("List name", text: $newName)
                Button("Create") {
                    store.createList(name: newName.isEmpty ? "New List" : newName, team: newIsTeam)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give your list a name. You can toggle 6-slot battle-team mode inside it.")
            }
        }
    }

    private func listRow(_ list: PokemonList) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(list.name).font(.headline)
                if list.id == store.activeListID {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
            Text(list.countLabel)
                .font(.caption)
                .foregroundStyle(list.legalityWarning == nil ? Color.secondary : Color.red)
            if let warning = list.legalityWarning {
                Text(warning).font(.caption2).foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
    }

    private func startNewList() {
        newName = ""
        newIsTeam = true
        showingNew = true
    }

    private func deleteLists(at offsets: IndexSet) {
        offsets.map { store.lists[$0].id }.forEach { store.deleteList($0) }
    }
}
