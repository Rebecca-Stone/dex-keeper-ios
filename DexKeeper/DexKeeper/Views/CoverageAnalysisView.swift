import SwiftUI

struct CoverageAnalysisView: View {
    @EnvironmentObject private var store: ListStore

    private var members: [Species] { store.activeList.pokemon.compactMap { $0.species } }

    var body: some View {
        NavigationStack {
            Group {
                if members.isEmpty {
                    ContentUnavailableState(
                        title: "Nothing to analyze",
                        message: "Add Pokémon to “\(store.activeList.name)” to see coverage and weaknesses.",
                        systemImage: "chart.bar.xaxis"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            Text("Analyzing “\(store.activeList.name)”")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            weaknessSummary
                            defensiveTable
                            offensiveCoverage
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Battle Prep")
        }
    }

    // MARK: Shared weakness highlight

    private var weaknessSummary: some View {
        let shared = TeamAnalysis.sharedWeaknesses(for: members, threshold: 3)
        let gaps = TeamAnalysis.offensiveGaps(for: members)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Team Health").font(.headline)

            if shared.isEmpty {
                Label("No type hits 3+ of your team super-effectively. Solid defensive spread.",
                      systemImage: "checkmark.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Label("Shared weaknesses — watch out for:", systemImage: "exclamationmark.shield.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                FlowTypeBadges(types: shared.map { $0.attacking })
                Text(shared.map { "\($0.attacking.displayName) hits \($0.weak)" }
                        .joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if gaps.isEmpty {
                Label("Your STAB types cover every type super-effectively.",
                      systemImage: "bolt.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Label("Offensive gaps (no STAB hits these hard):", systemImage: "scope")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                FlowTypeBadges(types: gaps)
            }
        }
        .cardStyle()
    }

    // MARK: Defensive table

    private var defensiveTable: some View {
        let rows = TeamAnalysis.defensive(for: members)
            .sorted { $0.pressure > $1.pressure }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Defensive Coverage").font(.headline)
            Text("How many of your \(members.count) Pokémon are weak / resist each attacking type.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(rows) { row in
                HStack(spacing: 10) {
                    TypeBadge(type: row.attacking, compact: true)
                        .frame(width: 78, alignment: .leading)
                    countPill("\(row.weak)", color: .red, label: "weak", show: row.weak > 0)
                    countPill("\(row.resist)", color: .green, label: "resist", show: row.resist > 0)
                    countPill("\(row.immune)", color: .blue, label: "immune", show: row.immune > 0)
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .cardStyle()
    }

    private func countPill(_ value: String, color: Color, label: String, show: Bool) -> some View {
        Group {
            if show {
                HStack(spacing: 3) {
                    Text(value).font(.caption.bold().monospacedDigit())
                    Text(label).font(.caption2)
                }
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(color.opacity(0.18)))
                .foregroundStyle(color)
            }
        }
    }

    // MARK: Offensive coverage grid

    private var offensiveCoverage: some View {
        let rows = TeamAnalysis.offensive(for: members)
        let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Offensive Coverage (STAB)").font(.headline)
            Text("Green = at least one of your Pokémon hits this type super-effectively with its own type.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(rows) { row in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(row.covered ? Color.green : Color.red.opacity(0.7))
                            .frame(width: 8, height: 8)
                        Text(row.defending.displayName)
                            .font(.caption)
                        Spacer(minLength: 0)
                        if row.superEffectiveCount > 0 {
                            Text("\(row.superEffectiveCount)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .fill(row.defending.color.opacity(0.12)))
                }
            }
        }
        .cardStyle()
    }
}
