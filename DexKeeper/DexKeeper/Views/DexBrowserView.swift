import SwiftUI

struct DexBrowserView: View {
    private let dex = DexDatabase.shared

    @State private var filter = DexFilter()
    @State private var showingFilters = false
    @State private var search = ""

    private var filtered: [Species] {
        dex.all.filter { s in
            guard filter.matches(s) else { return false }
            return search.isEmpty
                || s.displayName.localizedCaseInsensitiveContains(search)
                || String(s.id) == search
        }
    }

    var body: some View {
        NavigationStack {
            list
                .navigationTitle("National Dex")
                .searchable(text: $search, prompt: "Name or number")
                .toolbar { filterButton }
                .sheet(isPresented: $showingFilters) {
                    DexFilterSheet(filter: $filter)
                }
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(filtered) { species in
                    NavigationLink(value: species) {
                        PokemonRow(species: species)
                    }
                }
            } header: {
                Text("\(filtered.count) of \(dex.all.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Species.self) { species in
            PokemonDetailView(species: species)
        }
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableState(
                    title: "No matches",
                    message: "Try a different name, number, or filter.",
                    systemImage: "magnifyingglass"
                )
            }
        }
    }

    private var filterButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingFilters = true
            } label: {
                Label("Filters", systemImage: filter.isActive
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
                if filter.isActive {
                    Text("\(filter.activeCount)")
                        .font(.caption2.bold())
                }
            }
        }
    }
}

/// Small reusable empty/error state (works on iOS 16+ without ContentUnavailableView).
struct ContentUnavailableState: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
