import SwiftUI

struct DexBrowserView: View {
    private let dex = DexDatabase.shared

    @State private var selectedType: PokemonType? = nil
    @State private var search = ""

    private var filtered: [Species] {
        dex.all.filter { s in
            let matchesType = selectedType.map { s.types.contains($0) } ?? true
            let matchesSearch = search.isEmpty
                || s.displayName.localizedCaseInsensitiveContains(search)
                || String(s.id) == search
            return matchesType && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            list
                .navigationTitle("National Dex")
                .searchable(text: $search, prompt: "Name or number")
                .toolbar { typeFilterMenu }
        }
    }

    private var list: some View {
        List(filtered) { species in
            NavigationLink(value: species) {
                PokemonRow(species: species)
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
                    message: "Try a different name, number, or type.",
                    systemImage: "magnifyingglass"
                )
            }
        }
    }

    private var typeFilterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    selectedType = nil
                } label: {
                    Label("All Types", systemImage: selectedType == nil ? "checkmark" : "circle")
                }
                Divider()
                ForEach(PokemonType.allCases) { type in
                    Button {
                        selectedType = (selectedType == type) ? nil : type
                    } label: {
                        Label(type.displayName, systemImage: selectedType == type ? "checkmark" : "circle")
                    }
                }
            } label: {
                Image(systemName: selectedType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    .foregroundStyle(selectedType?.color ?? .accentColor)
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
