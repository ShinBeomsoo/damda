import Foundation

struct TodoDaySnapshot: Codable {
    let date: Date
    let completed: [String]
    let uncompleted: [String]
    let snapshotAt: Date
}

/// Lightweight JSON-based snapshot store to preserve daily todo state
final class TodoSnapshotStore {
    static let shared = TodoSnapshotStore()

    private let baseURL: URL

    init(baseURL: URL? = nil) {
        if let baseURL {
            self.baseURL = baseURL
        } else {
            let appSup = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseURL = appSup.appendingPathComponent("TodoSnapshots", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.baseURL, withIntermediateDirectories: true)
    }

    private func fileURL(for day: Date) -> URL {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let comps = cal.dateComponents([.year, .month, .day], from: start)
        let name = String(format: "%04d-%02d-%02d.json", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
        return baseURL.appendingPathComponent(name)
    }

    func save(day: Date, completed: [String], uncompleted: [String]) {
        let snap = TodoDaySnapshot(date: Calendar.current.startOfDay(for: day), completed: completed, uncompleted: uncompleted, snapshotAt: Date())
        let url = fileURL(for: day)
        do {
            let data = try JSONEncoder().encode(snap)
            try data.write(to: url, options: .atomic)
        } catch {
            // Silent fail to avoid crashing UI
            print("TodoSnapshotStore save failed:", error.localizedDescription)
        }
    }

    func load(day: Date) -> TodoDaySnapshot? {
        let url = fileURL(for: day)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(TodoDaySnapshot.self, from: data)
        } catch {
            print("TodoSnapshotStore load failed:", error.localizedDescription)
            return nil
        }
    }
}


