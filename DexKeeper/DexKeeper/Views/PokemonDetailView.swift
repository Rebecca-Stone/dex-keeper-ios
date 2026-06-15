import SwiftUI

struct PokemonDetailView: View {
    let species: Species

    @EnvironmentObject private var store: TeamStore
    @State private var showShiny = false

    private let dex = DexDatabase.shared

    var body: some View {
        ScrollView {
            content(species)
        }
        .navigationTitle(species.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ p: Species) -> some View {
        VStack(spacing: 20) {
            header(p)
            addButton(p)
            statsSection(p)
            abilitiesSection(p)
            infoSection(p)
            evolutionSection(p)
            defensiveSection(p)
        }
        .padding()
    }

    // MARK: Header

    private func header(_ p: Species) -> some View {
        VStack(spacing: 10) {
            SpriteImage(
                url: showShiny ? p.shinyArtworkURL : p.artworkURL,
                size: 180,
                tint: p.types.first?.color ?? .gray
            )
            Button {
                showShiny.toggle()
            } label: {
                Label(showShiny ? "Normal" : "Shiny", systemImage: "sparkles")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            HStack(spacing: 8) {
                Text(String(format: "#%04d", p.id))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("·").foregroundStyle(.secondary)
                Text("\(p.genLabel) (\(p.region))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let badge = p.rarityBadge {
                    Text("\(badge.symbol) \(badge.label)")
                        .font(.caption.bold())
                        .foregroundStyle(p.isMythical ? .pink : .yellow)
                }
            }
            Text(p.genus)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TypeBadgeRow(types: p.types)
        }
        .frame(maxWidth: .infinity)
        .padding(.top)
    }

    private func addButton(_ p: Species) -> some View {
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

    // MARK: Stats

    private func statsSection(_ p: Species) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Base Stats", trailing: "Total \(p.statTotal)")
            ForEach(p.statList) { stat in
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

    // MARK: Abilities

    private func abilitiesSection(_ p: Species) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Abilities")
            let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(p.abilities, id: \.name) { ability in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ability.name).font(.subheadline.bold())
                        if ability.hidden {
                            Text("HIDDEN")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.purple)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ability.hidden ? Color.purple : Color.secondary.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
        .cardStyle()
    }

    // MARK: Info grid

    private func infoSection(_ p: Species) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Details")
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                infoCell("Height", p.heightDisplay)
                infoCell("Weight", p.weightDisplay)
                infoCell("Color", p.color)
                infoCell("Shape", p.shape)
                infoCell("Habitat", p.habitatDisplay)
                infoCell("Growth Rate", p.growthRate)
                infoCell("Capture Rate", "\(p.captureRate) / 255")
                infoCell("Base Happiness", "\(p.baseHappiness) / 255")
                infoCell("Egg Groups", p.eggGroups.isEmpty ? "—" : p.eggGroups.joined(separator: ", "))
                infoCell("Gender", p.genderDisplay)
            }
        }
        .cardStyle()
    }

    private func infoCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Evolution

    @ViewBuilder
    private func evolutionSection(_ p: Species) -> some View {
        let family = dex.family(of: p.id)
        if family.count > 1 {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Evolution Family")
                let columns = [GridItem(.adaptive(minimum: 84), spacing: 10)]
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(family, id: \.self) { fid in
                        if let member = dex.species(id: fid) {
                            evolutionMember(member, current: fid == p.id)
                        }
                    }
                }
                // Per-step methods.
                let steps = family
                    .compactMap { dex.species(id: $0) }
                    .filter { $0.evoFrom != 0 && !$0.evoHow.isEmpty }
                if !steps.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(steps, id: \.id) { s in
                            if let from = dex.species(id: s.evoFrom) {
                                Text("\(from.displayName) → \(s.displayName): \(s.evoHow)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .cardStyle()
        }
    }

    @ViewBuilder
    private func evolutionMember(_ member: Species, current: Bool) -> some View {
        let cell = VStack(spacing: 4) {
            SpriteImage(url: member.spriteURL, size: 56, tint: member.types.first?.color ?? .gray)
            Text(member.displayName)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(current ? .primary : .secondary)
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(current ? (member.types.first?.color ?? .accentColor) : .clear, lineWidth: 2)
        )

        if current {
            cell
        } else {
            NavigationLink(value: member) { cell }
                .buttonStyle(.plain)
        }
    }

    // MARK: Defensive

    private func defensiveSection(_ p: Species) -> some View {
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

    // MARK: Helpers

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
