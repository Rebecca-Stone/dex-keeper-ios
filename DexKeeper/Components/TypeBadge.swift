import SwiftUI

/// A small colored capsule showing a type name.
struct TypeBadge: View {
    let type: PokemonType
    var compact: Bool = false

    var body: some View {
        Text(type.displayName.uppercased())
            .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 3 : 5)
            .background(
                Capsule().fill(type.color)
            )
            .shadow(color: type.color.opacity(0.35), radius: 2, y: 1)
    }
}

/// Horizontal stack of badges for a list of types.
struct TypeBadgeRow: View {
    let types: [PokemonType]
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(types) { TypeBadge(type: $0, compact: compact) }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        TypeBadgeRow(types: [.fire, .flying])
        TypeBadgeRow(types: [.water], compact: true)
    }
    .padding()
}
