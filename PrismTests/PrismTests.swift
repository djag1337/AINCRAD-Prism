import XCTest
@testable import AINCRAD_Prism

@MainActor final class PrismTests: XCTestCase {
    func testThemeRoundTripAndPreservesAlpha() throws {
        var theme = Theme(); theme.name = "Test"; theme.colors.panel = "#11223388"; theme.geometry.circleDiameter = 72
        let data = try JSONEncoder().encode(theme), decoded = try JSONDecoder().decode(Theme.self, from: data)
        XCTAssertEqual(decoded, theme)
        XCTAssertEqual(NSColor(themeHex: decoded.colors.panel)?.themeHex, "#11223388")
    }
    func testStoreCreatesBackupsAndAssignsWithoutRemovingSettings() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("themes"), withIntermediateDirectories: true)
        let theme = Theme(), data = try JSONEncoder().encode(theme)
        try data.write(to: root.appendingPathComponent("themes/original.json"))
        let settings: [String:Any] = ["theme":"original", "playerName":"Kirito", "unrelated":true]
        try JSONSerialization.data(withJSONObject: settings).write(to: root.appendingPathComponent("settings.json"))
        let store = ThemeStore(root: root)
        store.theme.name = "Edited"; store.save(); store.assignGlobal("original")
        let result = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("settings.json"))) as! [String:Any]
        XCTAssertEqual(result["playerName"] as? String, "Kirito"); XCTAssertEqual(result["unrelated"] as? Bool, true)
        XCTAssertFalse((try FileManager.default.contentsOfDirectory(atPath: store.backupsURL.path)).isEmpty)
    }
}
