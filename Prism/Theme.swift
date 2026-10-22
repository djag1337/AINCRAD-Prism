import AppKit

struct Theme: Codable, Equatable {
    var schemaVersion = 1
    var name = "Aincrad Classic"
    var colors = Colors()
    var font = Font()
    var geometry = Geometry()
    var effects = Effects()
    var animation = Animation()
    var sounds = Sounds()

    /// The sizes and other numbers from `source`, keeping this theme's colours, names, fonts, sounds and on/off switches.
    func withNumbers(from source: Theme) -> Theme {
        var t = self
        t.geometry = source.geometry
        t.font.size = source.font.size
        t.font.captionSize = source.font.captionSize
        let info = t.effects.showInfoPanel, hud = t.effects.hud
        t.effects = source.effects
        t.effects.showInfoPanel = info
        t.effects.hud = hud
        let preset = t.animation.preset
        t.animation = source.animation
        t.animation.preset = preset
        return t
    }

    struct Colors: Codable, Equatable {
        var backdrop = "#00000000", panel = "#F7F7F8F2", panelText = "#43474E", panelBorder = "#FFFFFFE6"
        var hover = "#FFFFFFFF", accent = "#F5A623", accentText = "#FFFFFF", iconBadge = "#5D6169", iconGlyph = "#FFFFFF"
        var circle = "#F8F8F9F2", circleIcon = "#8E9299", circleBorder = "#FFFFFF", caption = "#FFFFFF"
        var captionShadow = "#000000CC", shadow = "#0000005C", infoFooter = "#E6E7EAF5", infoIcon = "#9095A0"
        var windowClose = "#FF5F57", windowMinimize = "#FEBC2E", windowZoom = "#28C840"
    }
    struct Font: Codable, Equatable { var family = "Rajdhani"; var size = 20.0; var captionSize = 22.0; var display = "Orbitron" }
    struct Geometry: Codable, Equatable {
        var circleDiameter = 54.0, circleSpacing = 16.0, itemWidth = 212.0, itemHeight = 38.0, itemSpacing = 5.0
        var columnGap = 20.0, cornerRadius = 4.0; var visibleRows = 6; var screenMargin = 40.0
        var infoPanelWidth = 230.0, infoPanelHeight = 340.0, infoPanelGap = 26.0, cursorOffsetX = 72.0, cursorOffsetY = 0.0, bubbleRadius = 9.0
    }
    struct Effects: Codable, Equatable {
        var borderWidth = 1.0, shadowRadius = 10.0, shadowOpacity = 0.35, selectedRingWidth = 2.0, selectedGlow = 12.0, glowOpacity = 0.65, tilt = 0.0
        var showInfoPanel = true, hud = true; var gradient = 0.07, shine = 0.7
    }
    struct Animation: Codable, Equatable {
        var preset = "classic", speed = 1.0, open = 0.30, stagger = 0.045, column = 0.22, rowStagger = 0.018
        var move = 0.20, highlight = 0.10, close = 0.14, dropDistance = 30.0, slideDistance = 18.0
    }
    struct Sounds: Codable, Equatable {
        var volume = 0.35, open = "builtin:open", select = "builtin:select", back = "builtin:back", close = "builtin:close", hover = "", error = "builtin:error"
    }
}

extension NSColor {
    convenience init?(themeHex: String) {
        var h = themeHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard (h.count == 6 || h.count == 8), let v = UInt64(h, radix: 16) else { return nil }
        let rgb = h.count == 8 ? v >> 8 : v, a = h.count == 8 ? CGFloat(v & 255) / 255 : 1
        self.init(srgbRed: CGFloat((rgb >> 16) & 255) / 255, green: CGFloat((rgb >> 8) & 255) / 255, blue: CGFloat(rgb & 255) / 255, alpha: a)
    }
    var themeHex: String {
        let c = usingColorSpace(.sRGB) ?? self
        let v = [c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent].map { Int(($0 * 255).rounded()) }
        return v[3] == 255 ? String(format: "#%02X%02X%02X", v[0],v[1],v[2]) : String(format: "#%02X%02X%02X%02X", v[0],v[1],v[2],v[3])
    }
}
