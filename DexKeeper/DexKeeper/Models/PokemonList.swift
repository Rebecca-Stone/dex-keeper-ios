import Foundation

/// One Pokémon in a list. Stores only id + user text; name/types/sprite are
/// looked up from the bundled dex. JSON shape matches the web app exactly:
/// `{ "id": 25, "nick": "Sparky", "note": "lead" }`.
struct PokemonEntry: Identifiable, Hashable, Codable {
    var id: Int
    var nick: String = ""
    var note: String = ""

    static let textMax = 240

    var species: Species? { DexDatabase.shared.species(id: id) }

    var displayName: String {
        if !nick.isEmpty { return nick }
        return species?.displayName ?? "#\(id)"
    }

    /// The real species name, shown alongside a nickname.
    var speciesName: String { species?.displayName ?? "#\(id)" }
    var types: [PokemonType] { species?.types ?? [] }
    var spriteURL: URL? { species?.spriteURL }
}

/// A named list of Pokémon. With `team` on, it's a 6-slot battle team with a
/// legality (slot-count) check. JSON shape matches the web app:
/// `{ "id": "<uuid>", "name": "My Team", "team": true, "pokemon": [...] }`.
struct PokemonList: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var team: Bool
    var pokemon: [PokemonEntry]

    static let teamCap = 6
    static let nameMax = 60

    init(id: UUID = UUID(), name: String, team: Bool = false, pokemon: [PokemonEntry] = []) {
        self.id = id
        self.name = name
        self.team = team
        self.pokemon = pokemon
    }

    func contains(_ pid: Int) -> Bool { pokemon.contains { $0.id == pid } }

    /// In team mode, adding is blocked once 6 slots are filled.
    var isFull: Bool { team && pokemon.count >= Self.teamCap }

    /// Slot-count legality message for a team, or `nil` if legal / not a team.
    var legalityWarning: String? {
        guard team, pokemon.count > Self.teamCap else { return nil }
        let over = pokemon.count - Self.teamCap
        return "Over the limit (\(pokemon.count)/\(Self.teamCap)) — remove \(over) to make this a legal team."
    }

    var countLabel: String {
        team ? "Team · \(pokemon.count)/\(Self.teamCap)" : "\(pokemon.count) Pokémon"
    }
}
