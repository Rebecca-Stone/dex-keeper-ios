import SwiftUI

/// Edits the nickname and note for one list entry (active list).
struct EntryEditorSheet: View {
    let entryID: Int

    @EnvironmentObject private var store: ListStore
    @Environment(\.dismiss) private var dismiss
    @State private var nick = ""
    @State private var note = ""

    private var entry: PokemonEntry? { store.activeList.pokemon.first { $0.id == entryID } }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nickname") {
                    TextField(entry?.speciesName ?? "Nickname", text: $nick)
                        .autocorrectionDisabled()
                }
                Section("Note") {
                    TextField("Notes (held item, role, EVs…)", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(entry?.speciesName ?? "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.setNick(entryID: entryID, nick)
                        store.setNote(entryID: entryID, note)
                        dismiss()
                    }.fontWeight(.semibold)
                }
            }
            .onAppear {
                nick = entry?.nick ?? ""
                note = entry?.note ?? ""
            }
        }
    }
}
