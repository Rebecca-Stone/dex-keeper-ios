import SwiftUI

struct TeamView: View {
    @EnvironmentObject private var store: TeamStore
    @State private var showingImportExport = false
    @State private var editingName = false
    @State private var draftName = ""

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
                    NavigationLink(value: member.id) {
                        memberRow(member)
                    }
                }
                .onDelete { store.remove(at: $0) }
                .onMove { store.move(from: $0, to: $1) }
            } header: {
                Text("\(store.team.members.count) / \(Team.maxSize)")
            }
        }
        .toolbar { EditButton() }
        .navigationDestination(for: Int.self) { id in
            PokemonDetailView(dexID: id)
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
