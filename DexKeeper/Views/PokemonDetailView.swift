import SwiftUI

struct PokemonDetailView: View {
    let dexID: Int

    @EnvironmentObject private var api: PokeAPIService
    @EnvironmentObject private var store: TeamStore

    @State private var pokemon: Pokemon?
    @State private var loadError = false

    var body: some View {
        ScrollView {
            if let pokemon {
                content(pokemon)
            } else if loadError {
                ContentUnavailableState(
                    title: "Couldn't load",
                    message: "Try again in a moment.",
                    systemImage: "exclamationmark.triangle"
                )
                .frame(minHeight: 400)
            } else {
                ProgressView().frame(minHeight: 400)
            }
        }
        .navigationTitle(pokemon?.displayName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @ViewBuilder
    private func content(_ p: Pokemon) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                SpriteImage(url: p.artworkURL, size: 180, tint: p.types.first?.color ?? .gray)
                Text(String(format: "#%03d", p.id))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                TypeBadgeRow(types: p.types)
            }
            .frame(maxWidth: .infinity)
            .padding(.top)

            addButton(p)
            statsSection(p)
            defensiveSection(p)
        }
        .padding()
    }

    private func addButton(_ p: Pokemon) -> some View {
        let onTeam = store.team.contains(p.id)
        let full = store.team.isFull
        return Button {
            store.add(p)
        } label: {
            Label(
                onTeam ? "On Your Team" : (full ? "Team Full" : "Add to Team"),
                systemImage: onTeam ? "checkmark.circle.fill" : "plus.circle.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(onTeam || full)
    }

    private func statsSection(_ p: Pokemon) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Base Stats", trailing: "Total \(p.statTotal)")
            ForEach(p.stats) { stat in
                HStack {
                    Text(stat.displayName)
                        .font(.subheadline)
                        .frame(width: 70, alignment: .leading)
                    Text("\(stat.value)")
                        .font(.subheadline.monospacedDigit().bold())
                        .frame(width: 40, alignment: .trailing)
                    ProgressView(value: Double(min(stat.value, 200)), total: 200)
                        .tint(statColor(stat.value))
                }
            }
        }
        .cardStyle()
    }

    private func defensiveSection(_ p: Pokemon) -> some View {
        // Group attacking types by the multiplier they deal to this Pokémon.
        let groups = Dictionary(grouping: PokemonType.allCases) { atk in
            TypeChart.multiplier(of: atk, against: p.types)
        }
        let order: [(Double, String)] = [
            (4, "Takes 4× from"), (2, "Weak to (2×)"),
            (0.5, "Resists (½×)"), (0.25, "Resists (¼×)"), (0, "Immune to")
        ]
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Defensive Matchups")
            ForEach(order, id: \.1) { value, label in
                if let types = groups[value], !types.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(label)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        FlowTypeBadges(types: types.sorted { $0.rawValue < $1.rawValue })
                    }
                }
            }
        }
        .cardStyle()
    }

    private func sectionHeader(_ title: String, trailing: String? = nil) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            if let trailing {
                Text(trailing).font(.caption.bold()).foregroundStyle(.secondary)
            }
        }
    }

    private func statColor(_ value: Int) -> Color {
        switch value {
        case ..<60:  return .red
        case ..<90:  return .orange
        case ..<120: return .green
        default:     return .blue
        }
    }

    private func load() async {
        guard pokemon == nil else { return }
        do { pokemon = try await api.fetchPokemon(id: dexID) }
        catch { loadError = true }
    }
}

/// Wrapping rows of badges (simple flow layout for iOS 16).
struct FlowTypeBadges: View {
    let types: [PokemonType]
    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 6)]
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(types) { TypeBadge(type: $0, compact: true) }
        }
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}
