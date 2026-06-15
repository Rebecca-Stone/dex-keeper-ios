import Foundation
import SwiftUI

/// Holds the current team, persists it to UserDefaults, and handles JSON
/// export / import.
@MainActor
final class TeamStore: ObservableObject {
    @Published var team: Team {
        didSet { save() }
    }

    private let key = "dexkeeper.team.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Team.self, from: data) {
            self.team = decoded
        } else {
            self.team = Team()
        }
    }

    // MARK: Mutations

    @discardableResult
    func add(_ pokemon: Pokemon) -> Bool {
        guard !team.isFull, !team.contains(pokemon.id) else { return false }
        team.members.append(TeamMember(pokemon: pokemon))
        return true
    }

    func remove(at offsets: IndexSet) {
        team.members.remove(atOffsets: offsets)
    }

    func remove(id: Int) {
        team.members.removeAll { $0.id == id }
    }

    func move(from source: IndexSet, to destination: Int) {
        team.members.move(fromOffsets: source, toOffset: destination)
    }

    func clear() {
        team.members.removeAll()
    }

    func rename(_ name: String) {
        team.name = name
    }

    // MARK: Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(team) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: Export / Import

    func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(team),
              let string = String(data: data, encoding: .utf8) else { return "{}" }
        return string
    }

    enum ImportError: LocalizedError {
        case invalidJSON
        var errorDescription: String? {
            switch self {
            case .invalidJSON: return "That doesn't look like a valid Dex Keeper team."
            }
        }
    }

    func importJSON(_ string: String) throws {
        guard let data = string.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(Team.self, from: data) else {
            throw ImportError.invalidJSON
        }
        var imported = decoded
        imported.id = UUID()
        if imported.members.count > Team.maxSize {
            imported.members = Array(imported.members.prefix(Team.maxSize))
        }
        team = imported
    }
}
