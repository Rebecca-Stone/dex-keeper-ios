import SwiftUI

/// A single row in the dex browser. Sprite + name + type badges, all sourced
/// from the bundled dex (no network fetch — only the sprite image loads lazily).
struct PokemonRow: View {
    let species: Species

    var body: some View {
        HStack(spacing: 12) {
            SpriteImage(url: species.spriteURL, size: 52, tint: species.types.first?.color ?? .gray)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(species.displayName)
                        .font(.headline)
                    Text(String(format: "#%03d", species.id))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                TypeBadgeRow(types: species.types, compact: true)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
