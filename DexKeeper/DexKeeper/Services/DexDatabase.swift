import Foundation

/// Loads the bundled Pokédex (`dex.json`) once and serves it from memory.
/// Pure static data, so a singleton rather than an `ObservableObject`.
final class DexDatabase {
    static let shared = DexDatabase()

    /// All species, in national-dex order.
    let all: [Species]

    private let byID: [Int: Species]
    private let children: [Int: [Int]]   // pre-evo id -> next-stage ids

    private init() {
        let loaded: [Species] = DexDatabase.load("dex")
        all = loaded
        byID = Dictionary(loaded.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        var kids: [Int: [Int]] = [:]
        for s in loaded where s.evoFrom != 0 {
            kids[s.evoFrom, default: []].append(s.id)
        }
        children = kids
    }

    func species(id: Int) -> Species? { byID[id] }

    /// Full evolutionary family (walks to the root, then collects every
    /// descendant so branches like Eevee are included), sorted by dex id.
    func family(of id: Int) -> [Int] {
        guard byID[id] != nil else { return [] }
        var root = id
        while let s = byID[root], s.evoFrom != 0 { root = s.evoFrom }
        var out: [Int] = []
        func walk(_ i: Int) {
            out.append(i)
            for child in children[i] ?? [] { walk(child) }
        }
        walk(root)
        return out.sorted()
    }

    /// Direct next-stage evolutions of a species (empty if fully evolved).
    func evolutions(of id: Int) -> [Int] { (children[id] ?? []).sorted() }

    private static func load<T: Decodable>(_ name: String) -> [T] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([T].self, from: data) else {
            assertionFailure("Missing or invalid bundled resource: \(name).json")
            return []
        }
        return decoded
    }
}
