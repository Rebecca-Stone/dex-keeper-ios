import SwiftUI

/// One list's roster: members with nicknames & notes, reorder, evolve, the
/// 6-slot team-mode toggle, and export/import.
struct RosterView: View {
    let listID: UUID

    @EnvironmentObject private var store: ListStore
    @State private var showingImportExport = false
    @State private var renaming = false
    @State private var draftName = ""
    @State private var editingEntry: Int?
    @State private var evolving: PokemonEntry?

    private var list: PokemonList? { store.lists.first { $0.id == listID } }

    var body: some View {
        Group {
            if let list {
                content(list)
            } else {
                ContentUnavailableState(
                    title: "List not found",
                    message: "It may have been deleted.",
                    systemImage: "questionmark.folder"
                )
            }
        }
        .navigationTitle(list?.name ?? "List")
        .navigationBarTitleDisplayMode(.inline)
        // Mutations target the active list, so make this list active while viewing.
        .onAppear { store.setActive(listID) }
        .sheet(isPresented: $showingImportExport) { ImportExportView() }
        .sheet(item: Binding(get: { editingEntry.map { EntryRef(id: $0) } },
                             set: { editingEntry = $0?.id })) { ref in
            EntryEditorSheet(entryID: ref.id)
        }
        .alert("List Name", isPresented: $renaming) {
            TextField("Name", text: $draftName)
            Button("Save") { store.renameList(listID, to: draftName) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Evolve \(evolving?.displayName ?? "")",
            isPresented: Binding(get: { evolving != nil }, set: { if !$0 { evolving = nil } }),
            titleVisibility: .visible,
            presenting: evolving
        ) { entry in
            ForEach(evolutionOptions(for: entry), id: \.self) { eid in
                if let s = DexDatabase.shared.species(id: eid) {
                    Button("Evolve into \(s.displayName)") { store.evolve(entryID: entry.id, into: eid) }
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ list: PokemonList) -> some View {
        if list.pokemon.isEmpty {
            ContentUnavailableState(
                title: "No Pokémon yet",
                message: "Browse the dex and tap “Add” to fill this list.",
                systemImage: "rectangle.stack.badge.plus"
            )
            .toolbar { toolbarContent(list) }
        } else {
            List {
                Section {
                    ForEach(list.pokemon) { entry in
                        rowContent(entry)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) { evolveSwipe(entry) }
                            .swipeActions(edge: .trailing) {
                                Button { editingEntry = entry.id } label: {
                                    Label("Edit", systemImage: "pencil")
                                }.tint(.blue)
                            }
                    }
                    .onDelete { store.remove(at: $0) }
                    .onMove { store.move(from: $0, to: $1) }
                } header: {
                    Text(list.countLabel)
                        .foregroundStyle(list.legalityWarning == nil ? Color.secondary : Color.red)
                } footer: {
                    if let warning = list.legalityWarning {
                        Text(warning).foregroundStyle(.red)
                    }
                }

                Section {
                    Toggle("6-slot battle team", isOn: Binding(
                        get: { list.team },
                        set: { store.setTeamMode(listID, $0) }
                    ))
                }
            }
            .toolbar { toolbarContent(list) }
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent(_ list: PokemonList) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { draftName = list.name; renaming = true } label: { Image(systemName: "pencil") }
        }
        ToolbarItem(placement: .topBarTrailing) { EditButton() }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { showingImportExport = true } label: {
                    Label("Export / Import", systemImage: "square.and.arrow.up")
                }
                if !list.pokemon.isEmpty {
                    Button(role: .destructive) { store.clearActive() } label: {
                        Label("Clear List", systemImage: "trash")
                    }
                }
            } label: { Image(systemName: "ellipsis.circle") }
        }
    }

    @ViewBuilder
    private func rowContent(_ entry: PokemonEntry) -> some View {
        if let species = entry.species {
            NavigationLink(value: species) { memberRow(entry) }
        } else {
            memberRow(entry)
        }
    }

    private func memberRow(_ entry: PokemonEntry) -> some View {
        HStack(spacing: 12) {
            SpriteImage(url: entry.spriteURL, size: 48, tint: entry.types.first?.color ?? .gray)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.displayName).font(.headline)
                    if !entry.nick.isEmpty {
                        Text(entry.speciesName).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if !entry.note.isEmpty {
                    Text(entry.note).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                TypeBadgeRow(types: entry.types, compact: true)
            }
        }
        .padding(.vertical, 2)
    }

    private func evolutionOptions(for entry: PokemonEntry) -> [Int] {
        DexDatabase.shared.evolutions(of: entry.id).filter { id in
            !(list?.contains(id) ?? false)
        }
    }

    @ViewBuilder
    private func evolveSwipe(_ entry: PokemonEntry) -> some View {
        let options = evolutionOptions(for: entry)
        if !options.isEmpty {
            Button {
                if options.count == 1 {
                    store.evolve(entryID: entry.id, into: options[0])
                } else {
                    evolving = entry
                }
            } label: {
                Label("Evolve", systemImage: "arrow.up.circle.fill")
            }
            .tint(.green)
        }
    }
}

/// Identifiable wrapper so an entry id can drive a `.sheet(item:)`.
private struct EntryRef: Identifiable { let id: Int }
