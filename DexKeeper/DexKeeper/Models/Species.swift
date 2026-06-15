import Foundation

/// One ability, with the hidden-ability flag.
struct Ability: Codable, Hashable {
    let name: String
    let hidden: Bool
}

/// A full Pokédex entry, decoded from the bundled `dex.json`. This is the
/// app's offline source of truth — shared with the sister web app's dataset
/// (see Tools/generate-dex-data.mjs). All display data comes from here; only
/// sprite images are fetched over the network.
struct Species: Identifiable, Hashable, Codable {
    let id: Int                 // national dex id
    let name: String
    let gen: Int                // 1–9
    let region: String          // "Kanto", "Johto", …
    let habitat: String         // "Grassland", "Unknown", …
    let stats: [Int]            // [HP, Atk, Def, SpA, SpD, Spe]
    let evoFrom: Int            // pre-evolution dex id, 0 if none
    let rarity: String          // "regular" | "legendary" | "mythical"
    let abilities: [Ability]
    let genus: String           // "Seed Pokémon"
    let heightDm: Int           // decimetres
    let weightHg: Int           // hectograms
    let captureRate: Int        // 0–255
    let baseHappiness: Int      // 0–255
    let growthRate: String
    let genderRate: Int         // eighths female; -1 = genderless
    let eggGroups: [String]
    let color: String
    let shape: String
    let evoHow: String          // how it evolves FROM its pre-evolution
    let types: [PokemonType]

    var displayName: String { name.replacingOccurrences(of: "-", with: " ").capitalized }

    var statTotal: Int { stats.reduce(0, +) }

    /// Stats as `[Stat]` so existing stat views can render them unchanged.
    var statList: [Stat] {
        let names = ["hp", "attack", "defense", "special-attack", "special-defense", "speed"]
        return zip(names, stats).map { Stat(name: $0.0, value: $0.1) }
    }

    var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }

    var artworkURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }

    var shinyArtworkURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/\(id).png")
    }
}

// MARK: - Display helpers

extension Species {
    /// "Gen III" style label.
    var genLabel: String {
        let roman = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
        return "Gen \(roman.indices.contains(gen - 1) ? roman[gen - 1] : String(gen))"
    }

    var heightDisplay: String { String(format: "%.1f m", Double(heightDm) / 10) }
    var weightDisplay: String { String(format: "%.1f kg", Double(weightHg) / 10) }

    /// Habitat only exists for Gens I–III; everything else reads "Unknown".
    var habitatDisplay: String {
        habitat == "Unknown" ? "Unknown (Gen IV+)" : habitat
    }

    /// "88% ♂ / 13% ♀" or "Genderless".
    var genderDisplay: String {
        guard genderRate >= 0 else { return "Genderless" }
        let female = Int((Double(genderRate) / 8 * 100).rounded())
        return "\(100 - female)% ♂ / \(female)% ♀"
    }

    var isLegendary: Bool { rarity == "legendary" }
    var isMythical: Bool { rarity == "mythical" }

    /// Badge for legendary/mythical species, `nil` for regular.
    var rarityBadge: (symbol: String, label: String)? {
        switch rarity {
        case "legendary": return ("★", "Legendary")
        case "mythical":  return ("✦", "Mythical")
        default:          return nil
        }
    }
}
