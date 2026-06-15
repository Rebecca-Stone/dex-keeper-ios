import SwiftUI

/// A single row in the dex browser. Shows sprite + name immediately, then
/// lazily loads type badges (cached by the service).
struct PokemonRow: View {
    let entry: DexEntry
    @EnvironmentObject private var api: PokeAPIService

    @State private var types: [PokemonType] = []

    var body: some View {
        HStack(spacing: 12) {
            SpriteImage(url: entry.spriteURL, size: 52, tint: types.first?.color ?? .gray)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.headline)
                    Text(String(format: "#%03d", entry.id))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if types.isEmpty {
                    Text("Loading…")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    TypeBadgeRow(types: types, compact: true)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .task(id: entry.id) {
            guard types.isEmpty else { return }
            if let p = try? await api.fetchPokemon(id: entry.id) {
                types = p.types
            }
        }
    }
}
