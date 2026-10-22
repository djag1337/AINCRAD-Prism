import SwiftUI

@main struct PrismApp: App {
    @StateObject private var store = ThemeStore()
    init() { PrismStyle.registerFonts() }
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(store).frame(minWidth: 1040, minHeight: 700) }
        .windowStyle(.titleBar)
        .commands { CommandGroup(replacing: .saveItem) { Button("Save Theme") { store.save() }.keyboardShortcut("s").disabled(!store.dirty) } }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: ThemeStore
    @State private var importing = false
    @State private var exporting = false
    private var accent: Color { PrismStyle.accent(for: store.theme) }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 8) {
                Text("THEMES").font(PrismStyle.label()).tracking(2).foregroundStyle(.secondary).padding(.horizontal, 6)
                List(store.ids, id: \.self, selection: Binding(get: { store.selection }, set: { store.select($0) })) { id in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.selection == id ? store.theme.name : displayName(id))
                            .font(PrismStyle.body(15)).fontWeight(id == store.globalTheme ? .semibold : .regular)
                        HStack(spacing: 5) {
                            Text(id).font(.caption).foregroundStyle(.secondary)
                            if id == store.globalTheme { Text("AINCRAD").badgeStyle(accent) }
                            if id == store.browserTheme { Text("BROWSER").badgeStyle(.secondary) }
                        }
                    }.tag(id)
                }
                HStack {
                    Button(action: store.create) { Image(systemName: "plus") }.help("New theme")
                    Button(action: store.duplicate) { Image(systemName: "plus.square.on.square") }.help("Duplicate")
                    Button(role: .destructive, action: store.delete) { Image(systemName: "trash") }.help("Delete")
                    Spacer()
                    Button("Import…") { importing = true }
                }
            }.padding(10).navigationSplitViewColumnWidth(min: 230, ideal: 270)
        } detail: {
            VStack(spacing: 0) {
                toolbar
                Rectangle().fill(accent).frame(height: 2)
                HSplitView { ThemeEditor().environmentObject(store); ThemePreview(theme: store.theme).frame(minWidth: 310, idealWidth: 360) }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in if case .success(let url) = result { store.importTheme(url) } }
        .fileExporter(isPresented: $exporting, document: ThemeDocument(theme: store.theme), contentType: .json, defaultFilename: store.selection) { result in if case .success(let url) = result { store.message = "Exported \(url.lastPathComponent)." } }
        .tint(accent)
        .alert("AINCRAD Prism", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) { Button("OK") {} } message: { Text(store.message ?? "") }
    }
    private var toolbar: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("AINCRAD PRISM").font(PrismStyle.title(18)).tracking(3).foregroundStyle(accent).lineLimit(1).fixedSize()
                Text("The sole theme workshop for the AINCRAD ecosystem").font(PrismStyle.body(13)).foregroundStyle(.secondary)
            }
            Spacer()
            Menu("Assign") {
                Button("Use across AINCRAD") { store.assignGlobal(store.selection) }
                Button("Browser follows AINCRAD") { store.assignBrowser("follow") }
                Button("Use only in Browser") { store.assignBrowser(store.selection) }
            }.disabled(store.selection.isEmpty)
            Button("Migration Backup") { store.migrateAndBackup() }.help("Make a complete snapshot of existing themes and assignments")
            Menu("Copy sizes to…") {
                Button("All other themes") { store.copySizes(to: store.ids) }
                Divider()
                ForEach(store.ids.filter { $0 != store.selection }, id: \.self) { id in
                    Button(id) { store.copySizes(to: [id]) }
                }
            }
            .disabled(store.selection.isEmpty || store.ids.count < 2 || store.dirty)
            .help("Copy this theme's sizes and other numbers to other themes. Colours, names and fonts stay as they are. Save first.")
            Button("Export…") { exporting = true }.disabled(store.selection.isEmpty)
            Button("Revert", action: store.revert).disabled(!store.dirty)
            Button("Save", action: store.save).buttonStyle(.borderedProminent).disabled(!store.dirty)
        }.padding(12)
    }
    private func displayName(_ id: String) -> String {
        guard let data = try? Data(contentsOf: store.themeURL(id)), let t = try? JSONDecoder().decode(Theme.self, from: data) else { return id }
        return t.name
    }
}

extension View {
    func badgeStyle(_ color: Color) -> some View {
        self.font(PrismStyle.label(9)).foregroundStyle(color).padding(.horizontal, 5).padding(.vertical, 1)
            .background(color.opacity(0.16), in: Capsule())
    }
}

import UniformTypeIdentifiers
struct ThemeDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json]
    let theme: Theme
    init(theme: Theme) { self.theme = theme }
    init(configuration: ReadConfiguration) throws { theme = try JSONDecoder().decode(Theme.self, from: configuration.file.regularFileContents ?? Data()) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]; return .init(regularFileWithContents: try e.encode(theme)) }
}
