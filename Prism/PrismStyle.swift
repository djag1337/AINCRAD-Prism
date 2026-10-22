import AppKit
import SwiftUI

/// Prism's look: the launcher's own fonts (Orbitron for titles, Rajdhani for text) and the selected theme's accent.
enum PrismStyle {
    /// Registers the bundled fonts once, at launch. Xcode may place them at the bundle root or in Fonts/.
    static func registerFonts() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
        for url in urls { CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) }
    }

    static func title(_ size: CGFloat) -> Font { .custom("Orbitron", size: size).weight(.semibold) }
    static func body(_ size: CGFloat) -> Font { .custom("Rajdhani", size: size).weight(.medium) }
    static func label(_ size: CGFloat = 11) -> Font { .custom("Rajdhani", size: size).weight(.bold) }

    /// The selected theme's accent, or orange if the colour can't be read.
    static func accent(for theme: Theme) -> Color {
        Color(nsColor: NSColor(themeHex: theme.colors.accent) ?? .orange)
    }
}
