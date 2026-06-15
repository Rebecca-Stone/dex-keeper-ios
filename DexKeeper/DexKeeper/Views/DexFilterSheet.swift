import SwiftUI

/// Filter controls for the dex browser: type, generation, rarity (primary)
/// and habitat, color, shape (secondary). Mirrors the web app's filter panel.
struct DexFilterSheet: View {
    @Binding var filter: DexFilter
    @Environment(\.dismiss) private var dismiss

    private let dex = DexDatabase.shared

    private var resultCount: Int {
        dex.all.lazy.filter { filter.matches($0) }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $filter.type) {
                        Text("Any").tag(PokemonType?.none)
                        ForEach(PokemonType.allCases) { t in
                            Text(t.displayName).tag(PokemonType?.some(t))
                        }
                    }
                    Picker("Generation", selection: $filter.generation) {
                        Text("Any").tag(Int?.none)
                        ForEach(dex.generations, id: \.self) { g in
                            Text("Gen \(g) · \(dex.regionName(forGen: g))").tag(Int?.some(g))
                        }
                    }
                    Picker("Rarity", selection: $filter.rarity) {
                        Text("Any").tag(String?.none)
                        Text("Regular").tag(String?.some("regular"))
                        Text("Legendary ★").tag(String?.some("legendary"))
                        Text("Mythical ✦").tag(String?.some("mythical"))
                    }
                }

                Section("More filters") {
                    Picker("Habitat", selection: $filter.habitat) {
                        Text("Any").tag(String?.none)
                        ForEach(dex.habitats, id: \.self) { h in
                            Text(h == "Unknown" ? "Unknown (Gen IV+)" : h).tag(String?.some(h))
                        }
                    }
                    Picker("Color", selection: $filter.color) {
                        Text("Any").tag(String?.none)
                        ForEach(dex.colors, id: \.self) { c in
                            Text(c).tag(String?.some(c))
                        }
                    }
                    Picker("Shape", selection: $filter.shape) {
                        Text("Any").tag(String?.none)
                        ForEach(dex.shapes, id: \.self) { s in
                            Text(s).tag(String?.some(s))
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { filter.reset() }
                        .disabled(!filter.isActive)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Show \(resultCount)") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
