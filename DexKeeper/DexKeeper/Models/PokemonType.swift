import SwiftUI

/// The 18 Pokémon types (Gen 6+).
enum PokemonType: String, CaseIterable, Codable, Identifiable, Hashable {
    case normal, fire, water, electric, grass, ice
    case fighting, poison, ground, flying, psychic, bug
    case rock, ghost, dragon, dark, steel, fairy

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    /// Standard type color palette.
    var color: Color {
        switch self {
        case .normal:   return Color(hex: "#A8A77A")
        case .fire:     return Color(hex: "#EE8130")
        case .water:    return Color(hex: "#6390F0")
        case .electric: return Color(hex: "#F7D02C")
        case .grass:    return Color(hex: "#7AC74C")
        case .ice:      return Color(hex: "#96D9D6")
        case .fighting: return Color(hex: "#C22E28")
        case .poison:   return Color(hex: "#A33EA1")
        case .ground:   return Color(hex: "#E2BF65")
        case .flying:   return Color(hex: "#A98FF3")
        case .psychic:  return Color(hex: "#F95587")
        case .bug:      return Color(hex: "#A6B91A")
        case .rock:     return Color(hex: "#B6A136")
        case .ghost:    return Color(hex: "#735797")
        case .dragon:   return Color(hex: "#6F35FC")
        case .dark:     return Color(hex: "#705746")
        case .steel:    return Color(hex: "#B7B7CE")
        case .fairy:    return Color(hex: "#D685AD")
        }
    }

    /// SF Symbol used as a small glyph in some views.
    var symbol: String {
        switch self {
        case .fire:     return "flame.fill"
        case .water:    return "drop.fill"
        case .electric: return "bolt.fill"
        case .grass:    return "leaf.fill"
        case .ice:      return "snowflake"
        case .psychic:  return "sparkles"
        case .ghost:    return "moon.fill"
        case .fairy:    return "star.fill"
        default:        return "circle.fill"
        }
    }

    init?(apiName: String) {
        self.init(rawValue: apiName.lowercased())
    }
}
