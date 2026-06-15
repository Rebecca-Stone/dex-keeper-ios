import Foundation

/// A lightweight entry from the national dex listing (id + name only).
struct DexEntry: Identifiable, Hashable {
    let id: Int
    let name: String

    var displayName: String { name.replacingOccurrences(of: "-", with: " ").capitalized }

    /// Small pixel sprite, fast to load in lists.
    var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }
}

/// A base stat for a Pokémon.
struct Stat: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    let value: Int

    var displayName: String {
        switch name {
        case "hp":              return "HP"
        case "attack":          return "Attack"
        case "defense":         return "Defense"
        case "special-attack":  return "Sp. Atk"
        case "special-defense": return "Sp. Def"
        case "speed":           return "Speed"
        default:                return name.capitalized
        }
    }
}

/// Full Pokémon detail.
struct Pokemon: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let types: [PokemonType]
    let stats: [Stat]

    var displayName: String { name.replacingOccurrences(of: "-", with: " ").capitalized }

    var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }

    var artworkURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }

    var statTotal: Int { stats.reduce(0) { $0 + $1.value } }
}

// MARK: - PokéAPI decoding DTOs

struct DexListResponse: Decodable {
    struct Result: Decodable {
        let name: String
        let url: String
        var id: Int? {
            url.split(separator: "/").last.flatMap { Int($0) }
        }
    }
    let results: [Result]
}

struct PokemonDTO: Decodable {
    struct TypeSlot: Decodable {
        struct TypeRef: Decodable { let name: String }
        let slot: Int
        let type: TypeRef
    }
    struct StatSlot: Decodable {
        struct StatRef: Decodable { let name: String }
        let base_stat: Int
        let stat: StatRef
    }
    let id: Int
    let name: String
    let types: [TypeSlot]
    let stats: [StatSlot]

    func toModel() -> Pokemon {
        let parsedTypes = types
            .sorted { $0.slot < $1.slot }
            .compactMap { PokemonType(apiName: $0.type.name) }
        let parsedStats = stats.map { Stat(name: $0.stat.name, value: $0.base_stat) }
        return Pokemon(id: id, name: name, types: parsedTypes, stats: parsedStats)
    }
}

struct TypeMembersDTO: Decodable {
    struct PokemonSlot: Decodable {
        struct Ref: Decodable {
            let name: String
            let url: String
            var id: Int? { url.split(separator: "/").last.flatMap { Int($0) } }
        }
        let pokemon: Ref
    }
    let pokemon: [PokemonSlot]
}
