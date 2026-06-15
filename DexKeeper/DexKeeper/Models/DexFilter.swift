import Foundation

/// Active dex-browser filters. Any `nil` field means "Any". All set fields
/// are AND-ed together (mirrors the web app's filter behavior).
struct DexFilter: Equatable {
    var type: PokemonType?
    var generation: Int?
    var rarity: String?      // "regular" | "legendary" | "mythical"
    var habitat: String?
    var color: String?
    var shape: String?

    var activeCount: Int {
        [type != nil, generation != nil, rarity != nil,
         habitat != nil, color != nil, shape != nil].filter { $0 }.count
    }

    var isActive: Bool { activeCount > 0 }

    func matches(_ s: Species) -> Bool {
        if let type, !s.types.contains(type) { return false }
        if let generation, s.gen != generation { return false }
        if let rarity, s.rarity != rarity { return false }
        if let habitat, s.habitat != habitat { return false }
        if let color, s.color != color { return false }
        if let shape, s.shape != shape { return false }
        return true
    }

    mutating func reset() { self = DexFilter() }
}
