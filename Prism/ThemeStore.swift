import AppKit
import Foundation

@MainActor final class ThemeStore: ObservableObject {
    static let aincrad = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/AINCRAD", isDirectory: true)
    static let browserPrefs = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/AINCRAD Browser/preferences.json")
    let root: URL
    var themesURL: URL { root.appendingPathComponent("themes", isDirectory: true) }
    var settingsURL: URL { root.appendingPathComponent("settings.json") }
    var backupsURL: URL { root.appendingPathComponent("backups/prism", isDirectory: true) }

    @Published var ids: [String] = []
    @Published var selection = ""
    @Published var theme = Theme()
    @Published var saved = Theme()
    @Published var globalTheme = ""
    @Published var browserTheme = "follow"
    @Published var message: String?
    var dirty: Bool { theme != saved }

    init(root: URL? = nil) { self.root = root ?? Self.aincrad; reload() }

    func reload() {
        do {
            try FileManager.default.createDirectory(at: themesURL, withIntermediateDirectories: true)
            ids = try FileManager.default.contentsOfDirectory(at: themesURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "json" }.map { $0.deletingPathExtension().lastPathComponent }.sorted()
            globalTheme = (readObject(settingsURL)?["theme"] as? String) ?? ids.first ?? ""
            browserTheme = (readObject(Self.browserPrefs)?["theme"] as? String) ?? "follow"
            select(ids.contains(selection) ? selection : (ids.contains(globalTheme) ? globalTheme : ids.first ?? ""))
        } catch { message = "Could not read themes: \(error.localizedDescription)" }
    }

    func select(_ id: String) {
        guard !id.isEmpty else { return }
        if dirty { message = "Save or revert the current theme before switching."; return }
        do {
            let value = try JSONDecoder().decode(Theme.self, from: Data(contentsOf: themeURL(id)))
            selection = id; theme = value; saved = value
        } catch { message = "\(id).json could not be read: \(error.localizedDescription)" }
    }

    func create() {
        if dirty { message = "Save or revert the current theme before creating another."; return }
        var value = Theme(); value.name = "New AINCRAD Theme"
        let id = freeID("new-aincrad-theme")
        do { try write(value, id: id, backup: false); reload(); select(id) } catch { message = error.localizedDescription }
    }
    func duplicate() {
        guard !selection.isEmpty else { return }
        var value = theme; value.name += " Copy"; let id = freeID(selection + "-copy")
        do { try write(value, id: id, backup: false); reload(); select(id) } catch { message = error.localizedDescription }
    }
    func save() { do { try write(theme, id: selection, backup: true); saved = theme; announce(); message = "Saved \(selection). A backup was kept." } catch { message = error.localizedDescription } }
    func revert() { theme = saved }
    func delete() {
        guard !selection.isEmpty, ids.count > 1 else { message = "Prism keeps at least one theme available."; return }
        guard selection != globalTheme && selection != browserTheme else { message = "Assign another theme before deleting this one."; return }
        do { try backup(themeURL(selection)); try FileManager.default.removeItem(at: themeURL(selection)); selection = ""; reload() } catch { message = error.localizedDescription }
    }
    /// Copies this (saved) theme's sizes and other numbers into the chosen themes. Their colours, names, fonts and sounds stay.
    /// Each changed file keeps a backup.
    func copySizes(to targets: [String]) {
        let targetIDs = targets.filter { $0 != selection && ids.contains($0) }
        guard !targetIDs.isEmpty else { return }
        do {
            for id in targetIDs {
                let existing = try JSONDecoder().decode(Theme.self, from: Data(contentsOf: themeURL(id)))
                try write(existing.withNumbers(from: theme), id: id, backup: true)
            }
            message = "Copied sizes to \(targetIDs.count) \(targetIDs.count == 1 ? "theme" : "themes"). Backups were kept."
        } catch { message = "Copy failed: \(error.localizedDescription)" }
    }

    func importTheme(_ url: URL) {
        do {
            let data = try Data(contentsOf: url), value = try JSONDecoder().decode(Theme.self, from: data)
            let id = freeID(url.deletingPathExtension().lastPathComponent)
            try write(value, id: id, backup: false); selection = ""; reload(); select(id); message = "Imported \(value.name)."
        } catch { message = "Import failed: \(error.localizedDescription)" }
    }
    func exportTheme(_ url: URL) { do { try encoded(theme).write(to: url, options: .atomic); message = "Exported \(url.lastPathComponent)." } catch { message = error.localizedDescription } }

    func assignGlobal(_ id: String) { do { try updateJSON(settingsURL, key: "theme", value: id); globalTheme = id; announce() } catch { message = error.localizedDescription } }
    func assignBrowser(_ id: String) { do { try updateJSON(Self.browserPrefs, key: "theme", value: id); browserTheme = id; announce(browser: true) } catch { message = error.localizedDescription } }

    func migrateAndBackup() {
        do {
            let stamp = Self.stamp(), destination = backupsURL.appendingPathComponent("migration-\(stamp)", isDirectory: true)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            for id in ids { try FileManager.default.copyItem(at: themeURL(id), to: destination.appendingPathComponent(id + ".json")) }
            if FileManager.default.fileExists(atPath: settingsURL.path) { try FileManager.default.copyItem(at: settingsURL, to: destination.appendingPathComponent("settings.json")) }
            if FileManager.default.fileExists(atPath: Self.browserPrefs.path) { try FileManager.default.copyItem(at: Self.browserPrefs, to: destination.appendingPathComponent("browser-preferences.json")) }
            message = "Migration snapshot created with \(ids.count) themes. No originals were changed."
        } catch { message = "Backup failed: \(error.localizedDescription)" }
    }

    func themeURL(_ id: String) -> URL { themesURL.appendingPathComponent(id + ".json") }
    func freeID(_ input: String) -> String {
        let clean = String(input.lowercased().map { $0.isLetter || $0.isNumber ? $0 : "-" }.split(separator: "-").joined(separator: "-"))
        let base = clean.isEmpty ? "aincrad-theme" : clean; var id = base, n = 2
        while FileManager.default.fileExists(atPath: themeURL(id).path) { id = "\(base)-\(n)"; n += 1 }; return id
    }
    private func write(_ value: Theme, id: String, backup shouldBackup: Bool) throws {
        guard !id.isEmpty else { throw CocoaError(.fileWriteInvalidFileName) }
        if shouldBackup { try backup(themeURL(id)) }
        try FileManager.default.createDirectory(at: themesURL, withIntermediateDirectories: true)
        try encoded(value).write(to: themeURL(id), options: .atomic)
    }
    private func encoded(_ value: Theme) throws -> Data { let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]; return try e.encode(value) }
    private func backup(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: url, to: backupsURL.appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)-\(Self.stamp()).json"))
    }
    private func updateJSON(_ url: URL, key: String, value: String) throws {
        try backup(url)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var object = readObject(url) ?? [:]; object[key] = value
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]); try data.write(to: url, options: .atomic)
    }
    private func readObject(_ url: URL) -> [String: Any]? { (try? Data(contentsOf: url)).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } }
    private func announce(browser: Bool = false) {
        DistributedNotificationCenter.default().postNotificationName(Notification.Name(browser ? "com.djag.aincrad.browser.prefsChanged" : "com.djag.aincrad.themeChanged"), object: nil, deliverImmediately: true)
    }
    private static func stamp() -> String { ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-") }
}
