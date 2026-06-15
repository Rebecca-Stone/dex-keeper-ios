import Foundation

/// A single base stat, used by the detail view's stats section.
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
