import Foundation

/// A single slot on a team. Stored self-contained so an imported team can
/// render without needing a network call.
struct TeamMember: Identifiable, Hashable, Codable {
    var id: Int                 // national dex id
    var name: String
    var types: [PokemonType]
    var nickname: String?

    var displayName: String {
        if let nickname, !nickname.isEmpty { return nickname }
        return name.replacingOccurrences(of: "-", with: " ").capitalized
    }

    var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }

    init(id: Int, name: String, types: [PokemonType], nickname: String? = nil) {
        self.id = id
        self.name = name
        self.types = types
        self.nickname = nickname
    }

    init(species: Species) {
        self.id = species.id
        self.name = species.name
        self.types = species.types
        self.nickname = nil
    }
}

/// A full team (up to 6 members) with a name.
struct Team: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var members: [TeamMember]

    static let maxSize = 6

    init(id: UUID = UUID(), name: String = "My Team", members: [TeamMember] = []) {
        self.id = id
        self.name = name
        self.members = members
    }

    var isFull: Bool { members.count >= Team.maxSize }

    func contains(_ id: Int) -> Bool { members.contains { $0.id == id } }
}
