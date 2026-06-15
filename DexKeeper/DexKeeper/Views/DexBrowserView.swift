import SwiftUI

struct DexBrowserView: View {
    @EnvironmentObject private var api: PokeAPIService

    @State private var entries: [DexEntry] = []
    @State private var filterIDs: Set<Int>? = nil
    @State private var selectedType: PokemonType? = nil
    @State private var search = ""
    @State private var isLoading = false
    @State private var loadError: String?

    private var filtered: [DexEntry] {
        entries.filter { entry in
            let matchesType = filterIDs.map { $0.contains(entry.id) } ?? true
            let matchesSearch = search.isEmpty
                || entry.displayName.localizedCaseInsensitiveContains(search)
                || String(entry.id) == search
            return matchesType && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && entries.isEmpty {
                    ProgressView("Loading the dex…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let loadError {
                    ContentUnavailableState(
                        title: "Couldn't load the dex",
                        message: loadError,
                        systemImage: "wifi.exclamationmark",
                        actionTitle: "Retry"
                    ) { Task { await loadDex() } }
                } else {
                    list
                }
            }
            .navigationTitle("National Dex")
            .searchable(text: $search, prompt: "Name or number")
            .toolbar { typeFilterMenu }
            .task { await loadDex() }
        }
    }

    private var list: some View {
        List(filtered) { entry in
            NavigationLink(value: entry) {
                PokemonRow(entry: entry)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: DexEntry.self) { entry in
            PokemonDetailView(dexID: entry.id)
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
                    filterIDs = nil
                } label: {
                    Label("All Types", systemImage: selectedType == nil ? "checkmark" : "circle")
                }
                Divider()
                ForEach(PokemonType.allCases) { type in
                    Button {
                        Task { await applyTypeFilter(type) }
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

    private func loadDex() async {
        guard entries.isEmpty else { return }
        isLoading = true
        loadError = nil
        do {
            entries = try await api.fetchDexEntries()
        } catch {
            loadError = "Check your connection and try again."
        }
        isLoading = false
    }

    private func applyTypeFilter(_ type: PokemonType) async {
        selectedType = type
        do {
            filterIDs = try await api.fetchMembers(of: type)
        } catch {
            filterIDs = nil
            selectedType = nil
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
