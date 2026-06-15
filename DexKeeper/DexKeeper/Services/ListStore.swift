import Foundation
import SwiftUI
import Combine

/// Holds the user's Pokémon lists, persists them locally, and handles JSON
/// export / import. Models match the web app's shape, and persistence is
/// isolated to `save()` / `load` so a server-sync layer can drop in later.
@MainActor
final class ListStore: ObservableObject {
    @Published private(set) var lists: [PokemonList]
    @Published var activeListID: UUID { didSet { UserDefaults.standard.set(activeListID.uuidString, forKey: Self.activeKey) } }

    private static let listsKey = "dexkeeper.lists.v1"
    private static let activeKey = "dexkeeper.activeList.v1"
    private static let legacyTeamKey = "dexkeeper.team.v1"

    init() {
        // Whether lists were already stored under the current key (vs seeded or
        // migrated from the legacy single-team format, which must be persisted).
        let hadStored = UserDefaults.standard.data(forKey: Self.listsKey) != nil
        let loaded = ListStore.loadLists()
        let initial = loaded.isEmpty ? [PokemonList(name: "My Team", team: true)] : loaded
        self.lists = initial

        if let raw = UserDefaults.standard.string(forKey: Self.activeKey),
           let uuid = UUID(uuidString: raw),
           initial.contains(where: { $0.id == uuid }) {
            self.activeListID = uuid
        } else {
            self.activeListID = initial[0].id
        }

        if !hadStored {
            save()
            UserDefaults.standard.removeObject(forKey: Self.legacyTeamKey)
        }
    }

    // MARK: Active list

    /// Always valid — the store keeps at least one list.
    var activeList: PokemonList {
        lists.first { $0.id == activeListID } ?? lists[0]
    }

    func setActive(_ id: UUID) {
        if lists.contains(where: { $0.id == id }) { activeListID = id }
    }

    private func mutateActive(_ body: (inout PokemonList) -> Void) {
        mutate(activeListID, body)
    }

    private func mutate(_ id: UUID, _ body: (inout PokemonList) -> Void) {
        guard let idx = lists.firstIndex(where: { $0.id == id }) else { return }
        body(&lists[idx])
        save()
    }

    // MARK: List CRUD

    @discardableResult
    func createList(name: String, team: Bool = false) -> UUID {
        let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(PokemonList.nameMax))
        let list = PokemonList(name: trimmed.isEmpty ? "New List" : trimmed, team: team)
        lists.append(list)
        activeListID = list.id
        save()
        return list.id
    }

    func deleteList(_ id: UUID) {
        lists.removeAll { $0.id == id }
        if lists.isEmpty { lists = [PokemonList(name: "My Team", team: true)] }
        if !lists.contains(where: { $0.id == activeListID }) { activeListID = lists[0].id }
        save()
    }

    func renameList(_ id: UUID, to name: String) {
        let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(PokemonList.nameMax))
        guard !trimmed.isEmpty else { return }
        mutate(id) { $0.name = trimmed }
    }

    func setTeamMode(_ id: UUID, _ on: Bool) {
        mutate(id) { $0.team = on }
    }

    // MARK: Entry mutations (active list)

    @discardableResult
    func add(_ species: Species) -> Bool {
        guard let idx = lists.firstIndex(where: { $0.id == activeListID }),
              !lists[idx].isFull, !lists[idx].contains(species.id) else { return false }
        lists[idx].pokemon.append(PokemonEntry(id: species.id))
        save()
        return true
    }

    /// Adds every not-yet-present family member of `species` to the active
    /// list, in dex order, respecting the team cap. Returns how many were added.
    @discardableResult
    func addEvolutionLine(of species: Species) -> Int {
        guard let idx = lists.firstIndex(where: { $0.id == activeListID }) else { return 0 }
        var added = 0
        for fid in DexDatabase.shared.family(of: species.id) {
            if lists[idx].isFull { break }
            guard !lists[idx].contains(fid) else { continue }
            lists[idx].pokemon.append(PokemonEntry(id: fid))
            added += 1
        }
        if added > 0 { save() }
        return added
    }

    /// Replaces an entry with one of its evolutions in place, keeping the slot
    /// position, nickname, and note. Fails if the evolution is already present.
    @discardableResult
    func evolve(entryID: Int, into newID: Int) -> Bool {
        guard let idx = lists.firstIndex(where: { $0.id == activeListID }),
              let pos = lists[idx].pokemon.firstIndex(where: { $0.id == entryID }),
              !lists[idx].contains(newID),
              DexDatabase.shared.species(id: newID) != nil else { return false }
        lists[idx].pokemon[pos].id = newID
        save()
        return true
    }

    func remove(at offsets: IndexSet) { mutateActive { $0.pokemon.remove(atOffsets: offsets) } }
    func move(from: IndexSet, to: Int) { mutateActive { $0.pokemon.move(fromOffsets: from, toOffset: to) } }
    func clearActive() { mutateActive { $0.pokemon.removeAll() } }

    func setNick(entryID: Int, _ text: String) {
        let clean = String(text.prefix(PokemonEntry.textMax))
        mutateActive { if let p = $0.pokemon.firstIndex(where: { $0.id == entryID }) { $0.pokemon[p].nick = clean } }
    }

    func setNote(entryID: Int, _ text: String) {
        let clean = String(text.prefix(PokemonEntry.textMax))
        mutateActive { if let p = $0.pokemon.firstIndex(where: { $0.id == entryID }) { $0.pokemon[p].note = clean } }
    }

    // MARK: Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(data, forKey: Self.listsKey)
        }
    }

    private static func loadLists() -> [PokemonList] {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: listsKey),
           let decoded = try? JSONDecoder().decode([PokemonList].self, from: data) {
            return decoded
        }
        // One-time migration from the old single-team format.
        if let data = ud.data(forKey: legacyTeamKey),
           let legacy = try? JSONDecoder().decode(LegacyTeam.self, from: data) {
            let entries = legacy.members.map { PokemonEntry(id: $0.id, nick: $0.nickname ?? "", note: "") }
            return [PokemonList(id: legacy.id ?? UUID(), name: legacy.name, team: true, pokemon: entries)]
        }
        return []
    }

    private struct LegacyTeam: Decodable {
        var id: UUID?
        var name: String
        var members: [LegacyMember]
    }
    private struct LegacyMember: Decodable {
        var id: Int
        var nickname: String?
    }

    // MARK: Export / Import

    func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(lists),
              let string = String(data: data, encoding: .utf8) else { return "[]" }
        return string
    }

    enum ImportError: LocalizedError {
        case invalidJSON
        case noLists
        var errorDescription: String? {
            switch self {
            case .invalidJSON: return "That doesn't look like valid Dex Keeper list data."
            case .noLists:     return "No importable lists were found."
            }
        }
    }

    /// Appends imported lists (matching the web app). Skips invalid/duplicate
    /// Pokémon ids, accepts legacy bare-number entries, drops empty lists, and
    /// gives every imported list a fresh id. Returns how many were added.
    @discardableResult
    func importJSON(_ string: String) throws -> Int {
        guard let data = string.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else {
            throw ImportError.invalidJSON
        }
        let rawLists: [Any]
        if let array = object as? [Any] { rawLists = array }
        else if let single = object as? [String: Any] { rawLists = [single] }
        else { throw ImportError.invalidJSON }

        let normalized = ListStore.normalize(rawLists)
        guard !normalized.isEmpty else { throw ImportError.noLists }

        lists.append(contentsOf: normalized)
        activeListID = normalized[0].id
        save()
        return normalized.count
    }

    private static func normalize(_ rawLists: [Any]) -> [PokemonList] {
        let size = DexDatabase.shared.all.count
        var result: [PokemonList] = []
        for case let raw as [String: Any] in rawLists {
            let name = String(((raw["name"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines).prefix(PokemonList.nameMax))
            guard !name.isEmpty, let pokeRaw = raw["pokemon"] as? [Any] else { continue }
            let team = (raw["team"] as? Bool) ?? false

            var seen = Set<Int>()
            var entries: [PokemonEntry] = []
            for item in pokeRaw {
                var pid: Int?
                var nick = "", note = ""
                if let number = item as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
                    pid = number.intValue                       // legacy bare number
                } else if let dict = item as? [String: Any] {
                    pid = (dict["id"] as? NSNumber)?.intValue
                    nick = String(((dict["nick"] as? String) ?? "").prefix(PokemonEntry.textMax))
                    note = String(((dict["note"] as? String) ?? "").prefix(PokemonEntry.textMax))
                }
                guard let id = pid, id >= 1, id <= size, !seen.contains(id) else { continue }
                seen.insert(id)
                entries.append(PokemonEntry(id: id, nick: nick, note: note))
            }
            guard !entries.isEmpty else { continue }            // drop empty lists
            result.append(PokemonList(name: name, team: team, pokemon: entries))
        }
        return result
    }
}
