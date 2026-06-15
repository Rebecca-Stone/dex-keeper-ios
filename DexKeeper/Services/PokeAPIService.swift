import Foundation

/// Talks to PokéAPI (https://pokeapi.co) and caches results in memory.
@MainActor
final class PokeAPIService: ObservableObject {
    static let shared = PokeAPIService()

    private let base = URL(string: "https://pokeapi.co/api/v2")!
    private let session: URLSession

    private var detailCache: [Int: Pokemon] = [:]
    private var typeMembersCache: [PokemonType: Set<Int>] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// The mainline national dex (Gen 1–9).
    func fetchDexEntries(limit: Int = 1025) async throws -> [DexEntry] {
        let url = base.appendingPathComponent("pokemon")
            .appending(queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "0")
            ])
        let (data, _) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(DexListResponse.self, from: data)
        return decoded.results.compactMap { result -> DexEntry? in
            guard let id = result.id, id <= limit else { return nil }
            return DexEntry(id: id, name: result.name)
        }
    }

    /// Full detail for a single Pokémon, cached by id.
    func fetchPokemon(id: Int) async throws -> Pokemon {
        if let cached = detailCache[id] { return cached }
        let url = base.appendingPathComponent("pokemon/\(id)")
        let (data, _) = try await session.data(from: url)
        let dto = try JSONDecoder().decode(PokemonDTO.self, from: data)
        let model = dto.toModel()
        detailCache[id] = model
        return model
    }

    /// All dex ids belonging to a type, cached.
    func fetchMembers(of type: PokemonType, maxID: Int = 1025) async throws -> Set<Int> {
        if let cached = typeMembersCache[type] { return cached }
        let url = base.appendingPathComponent("type/\(type.rawValue)")
        let (data, _) = try await session.data(from: url)
        let dto = try JSONDecoder().decode(TypeMembersDTO.self, from: data)
        let ids = Set(dto.pokemon.compactMap { $0.pokemon.id }.filter { $0 <= maxID })
        typeMembersCache[type] = ids
        return ids
    }
}
