import SwiftUI

struct TeamView: View {
    @EnvironmentObject private var store: TeamStore
    @State private var showingImportExport = false
    @State private var editingName = false
    @State private var draftName = ""
    @State private var evolving: TeamMember?

    var body: some View {
        NavigationStack {
            Group {
                if store.team.members.isEmpty {
                    ContentUnavailableState(
                        title: "No Pokémon yet",
                        message: "Browse the dex and tap “Add to Team” to start building.",
                        systemImage: "rectangle.stack.badge.plus"
                    )
                } else {
                    teamList
                }
            }
            .navigationTitle(store.team.name)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { startRename() } label: { Image(systemName: "pencil") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingImportExport = true
                        } label: { Label("Export / Import", systemImage: "square.and.arrow.up") }
                        if !store.team.members.isEmpty {
                            Button(role: .destructive) {
                                store.clear()
                            } label: { Label("Clear Team", systemImage: "trash") }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .sheet(isPresented: $showingImportExport) {
                ImportExportView()
            }
            .alert("Team Name", isPresented: $editingName) {
                TextField("Name", text: $draftName)
                Button("Save") { store.rename(draftName.isEmpty ? "My Team" : draftName) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var teamList: some View {
        List {
            Section {
                ForEach(store.team.members) { member in
                    rowContent(member)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            evolveSwipe(member)
                        }
                }
                .onDelete { store.remove(at: $0) }
                .onMove { store.move(from: $0, to: $1) }
            } header: {
                Text("\(store.team.members.count) / \(Team.maxSize)")
            }
        }
        .toolbar { EditButton() }
        .navigationDestination(for: Species.self) { species in
            PokemonDetailView(species: species)
        }
        .confirmationDialog(
            "Evolve \(evolving?.displayName ?? "")",
            isPresented: Binding(get: { evolving != nil }, set: { if !$0 { evolving = nil } }),
            titleVisibility: .visible,
            presenting: evolving
        ) { member in
            ForEach(evolutionOptions(for: member), id: \.self) { eid in
                if let s = DexDatabase.shared.species(id: eid) {
                    Button("Evolve into \(s.displayName)") {
                        store.evolve(memberID: member.id, into: eid)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowContent(_ member: TeamMember) -> some View {
        if let species = DexDatabase.shared.species(id: member.id) {
            NavigationLink(value: species) { memberRow(member) }
        } else {
            memberRow(member)
        }
    }

    /// Evolutions of a member that aren't already on the team.
    private func evolutionOptions(for member: TeamMember) -> [Int] {
        DexDatabase.shared.evolutions(of: member.id).filter { !store.team.contains($0) }
    }

    @ViewBuilder
    private func evolveSwipe(_ member: TeamMember) -> some View {
        let options = evolutionOptions(for: member)
        if !options.isEmpty {
            Button {
                if options.count == 1 {
                    store.evolve(memberID: member.id, into: options[0])
                } else {
                    evolving = member
                }
            } label: {
                Label("Evolve", systemImage: "arrow.up.circle.fill")
            }
            .tint(.green)
        }
    }

    private func memberRow(_ member: TeamMember) -> some View {
        HStack(spacing: 12) {
            SpriteImage(url: member.spriteURL, size: 48, tint: member.types.first?.color ?? .gray)
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName).font(.headline)
                TypeBadgeRow(types: member.types, compact: true)
            }
        }
        .padding(.vertical, 2)
    }

    private func startRename() {
        draftName = store.team.name
        editingName = true
    }
}
