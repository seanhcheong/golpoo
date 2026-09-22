import Foundation

/// Local-only storage for past swing analyses. No cloud sync or user
/// account in v1 — sessions are stored as one JSON file per session in
/// the app's Documents directory.
final class SwingSessionStore {
    private let directory: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appendingPathComponent("SwingSessions", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(_ result: SwingAnalysisResult) throws {
        let data = try JSONEncoder().encode(result)
        try data.write(to: fileURL(for: result.id), options: .atomic)
    }

    func loadAll() -> [SwingAnalysisResult] {
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .compactMap { url -> SwingAnalysisResult? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(SwingAnalysisResult.self, from: data)
            }
            .sorted { $0.date > $1.date }
    }

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString).appendingPathExtension("json")
    }
}
