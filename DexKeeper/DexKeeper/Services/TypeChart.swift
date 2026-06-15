import Foundation

/// Gen 6+ type effectiveness chart plus team coverage analysis.
enum TypeChart {

    /// attacking type -> [defending type: multiplier] for any non-1x entry.
    static let chart: [PokemonType: [PokemonType: Double]] = build()

    /// Effectiveness of one attacking type against a single defending type.
    static func effectiveness(of attacking: PokemonType, against defending: PokemonType) -> Double {
        chart[attacking]?[defending] ?? 1.0
    }

    /// Combined multiplier an attacking type deals to a (possibly dual-typed) defender.
    static func multiplier(of attacking: PokemonType, against defenderTypes: [PokemonType]) -> Double {
        defenderTypes.reduce(1.0) { $0 * effectiveness(of: attacking, against: $1) }
    }

    private static func build() -> [PokemonType: [PokemonType: Double]] {
        var result: [PokemonType: [PokemonType: Double]] = [:]
        func set(_ attacking: PokemonType,
                 x2: [PokemonType] = [],
                 half: [PokemonType] = [],
                 zero: [PokemonType] = []) {
            var m: [PokemonType: Double] = [:]
            x2.forEach { m[$0] = 2.0 }
            half.forEach { m[$0] = 0.5 }
            zero.forEach { m[$0] = 0.0 }
            result[attacking] = m
        }

        set(.normal,   half: [.rock, .steel], zero: [.ghost])
        set(.fire,     x2: [.grass, .ice, .bug, .steel], half: [.fire, .water, .rock, .dragon])
        set(.water,    x2: [.fire, .ground, .rock], half: [.water, .grass, .dragon])
        set(.electric, x2: [.water, .flying], half: [.electric, .grass, .dragon], zero: [.ground])
        set(.grass,    x2: [.water, .ground, .rock],
                       half: [.fire, .grass, .poison, .flying, .bug, .dragon, .steel])
        set(.ice,      x2: [.grass, .ground, .flying, .dragon], half: [.fire, .water, .ice, .steel])
        set(.fighting, x2: [.normal, .ice, .rock, .dark, .steel],
                       half: [.poison, .flying, .psychic, .bug, .fairy], zero: [.ghost])
        set(.poison,   x2: [.grass, .fairy], half: [.poison, .ground, .rock, .ghost], zero: [.steel])
        set(.ground,   x2: [.fire, .electric, .poison, .rock, .steel],
                       half: [.grass, .bug], zero: [.flying])
        set(.flying,   x2: [.grass, .fighting, .bug], half: [.electric, .rock, .steel])
        set(.psychic,  x2: [.fighting, .poison], half: [.psychic, .steel], zero: [.dark])
        set(.bug,      x2: [.grass, .psychic, .dark],
                       half: [.fire, .fighting, .poison, .flying, .ghost, .steel, .fairy])
        set(.rock,     x2: [.fire, .ice, .flying, .bug], half: [.fighting, .ground, .steel])
        set(.ghost,    x2: [.psychic, .ghost], half: [.dark], zero: [.normal])
        set(.dragon,   x2: [.dragon], half: [.steel], zero: [.fairy])
        set(.dark,     x2: [.psychic, .ghost], half: [.fighting, .dark, .fairy])
        set(.steel,    x2: [.ice, .rock, .fairy], half: [.fire, .water, .electric, .steel])
        set(.fairy,    x2: [.fighting, .dragon, .dark], half: [.fire, .poison, .steel])

        return result
    }
}

// MARK: - Team analysis

/// Defensive picture for one attacking type against the whole team.
struct DefensiveRow: Identifiable {
    let attacking: PokemonType
    var weak: Int = 0       // members taking > 1x
    var resist: Int = 0     // members taking < 1x (but > 0)
    var immune: Int = 0     // members taking 0x
    var neutral: Int = 0    // members taking exactly 1x

    var id: String { attacking.rawValue }
    /// Net pressure: positive means the team is collectively vulnerable.
    var pressure: Int { weak - resist - immune }
}

/// Offensive picture: how many members can hit a defending type super-effectively
/// using one of their own (STAB) types.
struct OffensiveRow: Identifiable {
    let defending: PokemonType
    var superEffectiveCount: Int = 0
    var id: String { defending.rawValue }
    var covered: Bool { superEffectiveCount > 0 }
}

enum TeamAnalysis {
    /// Build a defensive row per attacking type.
    static func defensive(for members: [Species]) -> [DefensiveRow] {
        PokemonType.allCases.map { attacking in
            var row = DefensiveRow(attacking: attacking)
            for member in members {
                let m = TypeChart.multiplier(of: attacking, against: member.types)
                if m == 0 { row.immune += 1 }
                else if m > 1 { row.weak += 1 }
                else if m < 1 { row.resist += 1 }
                else { row.neutral += 1 }
            }
            return row
        }
    }

    /// Attacking types that hit a lot of the team for super-effective damage.
    static func sharedWeaknesses(for members: [Species], threshold: Int = 3) -> [DefensiveRow] {
        defensive(for: members)
            .filter { $0.weak >= threshold }
            .sorted { $0.weak > $1.weak }
    }

    /// Offensive coverage using each member's own types as STAB.
    static func offensive(for members: [Species]) -> [OffensiveRow] {
        PokemonType.allCases.map { defending in
            var row = OffensiveRow(defending: defending)
            for member in members {
                let canHit = member.types.contains {
                    TypeChart.effectiveness(of: $0, against: defending) > 1
                }
                if canHit { row.superEffectiveCount += 1 }
            }
            return row
        }
    }

    /// Defending types no member can hit super-effectively with STAB.
    static func offensiveGaps(for members: [Species]) -> [PokemonType] {
        offensive(for: members).filter { !$0.covered }.map { $0.defending }
    }
}
