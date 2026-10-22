import AppKit
import SwiftUI

struct ThemeEditor: View {
    @EnvironmentObject var store: ThemeStore
    var body: some View {
        Form {
            Section("Identity") { TextField("Theme name", text: bind(\.name)) }
            colorSection("Core colours", [("Accent", \.colors.accent), ("Accent text", \.colors.accentText), ("Panel", \.colors.panel), ("Panel text", \.colors.panelText), ("Panel border", \.colors.panelBorder), ("Hover", \.colors.hover), ("Backdrop", \.colors.backdrop)])
            colorSection("Controls", [("Circle", \.colors.circle), ("Circle icon", \.colors.circleIcon), ("Circle border", \.colors.circleBorder), ("Icon badge", \.colors.iconBadge), ("Icon glyph", \.colors.iconGlyph), ("Info footer", \.colors.infoFooter), ("Info icon", \.colors.infoIcon)])
            colorSection("Window buttons", [("Close", \.colors.windowClose), ("Minimize", \.colors.windowMinimize), ("Zoom", \.colors.windowZoom)])
            Section("Typography") {
                TextField("Body family", text: bind(\.font.family)); TextField("Display family", text: bind(\.font.display))
                number("Body size", \.font.size, 9...40); number("Caption size", \.font.captionSize, 9...44)
            }
            Section("Geometry") {
                number("Circle diameter", \.geometry.circleDiameter, 30...110); number("Circle spacing", \.geometry.circleSpacing, 0...40)
                number("Item width", \.geometry.itemWidth, 120...400); number("Item height", \.geometry.itemHeight, 24...80)
                number("Item spacing", \.geometry.itemSpacing, 0...24); number("Column gap", \.geometry.columnGap, 0...60)
                number("Corner radius", \.geometry.cornerRadius, 0...30); number("Bubble radius", \.geometry.bubbleRadius, 0...36)
                Stepper("Visible rows: \(store.theme.geometry.visibleRows)", value: bind(\.geometry.visibleRows), in: 1...20)
                number("Screen margin", \.geometry.screenMargin, 0...120); number("Info width", \.geometry.infoPanelWidth, 120...500); number("Info height", \.geometry.infoPanelHeight, 180...700)
            }
            Section("Effects") {
                Toggle("Show info panel", isOn: bind(\.effects.showInfoPanel)); Toggle("HUD frame", isOn: bind(\.effects.hud))
                number("Border width", \.effects.borderWidth, 0...6); number("Shadow radius", \.effects.shadowRadius, 0...40)
                number("Shadow opacity", \.effects.shadowOpacity, 0...1); number("Selection glow", \.effects.selectedGlow, 0...40)
                number("Glow opacity", \.effects.glowOpacity, 0...1); number("Ring width", \.effects.selectedRingWidth, 0...8)
                number("Perspective tilt", \.effects.tilt, 0...25); number("Gradient", \.effects.gradient, 0...0.5); number("Shine", \.effects.shine, 0...1)
            }
            Section("Motion") {
                Picker("Preset", selection: bind(\.animation.preset)) { Text("Classic").tag("classic"); Text("Snappy").tag("snappy"); Text("Gentle").tag("gentle"); Text("Minimal").tag("minimal") }
                number("Speed", \.animation.speed, 0.25...3); number("Open", \.animation.open, 0...1); number("Close", \.animation.close, 0...1)
                number("Move", \.animation.move, 0...1); number("Highlight", \.animation.highlight, 0...0.5); number("Drop distance", \.animation.dropDistance, 0...100); number("Slide distance", \.animation.slideDistance, 0...100)
            }
            Section("Sounds") {
                number("Volume", \.sounds.volume, 0...1); TextField("Open", text: bind(\.sounds.open)); TextField("Select", text: bind(\.sounds.select)); TextField("Back", text: bind(\.sounds.back)); TextField("Close", text: bind(\.sounds.close)); TextField("Hover", text: bind(\.sounds.hover)); TextField("Error", text: bind(\.sounds.error))
            }
        }.formStyle(.grouped).frame(minWidth: 520)
    }
    private func bind<T>(_ path: WritableKeyPath<Theme,T>) -> Binding<T> { Binding(get: { store.theme[keyPath:path] }, set: { store.theme[keyPath:path] = $0 }) }
    @ViewBuilder private func colorSection(_ title: String, _ fields: [(String, WritableKeyPath<Theme,String>)]) -> some View { Section(title) { ForEach(fields, id: \.0) { label,path in ColorField(label: label, value: bind(path)) } } }
    @ViewBuilder private func number(_ title: String, _ path: WritableKeyPath<Theme,Double>, _ range: ClosedRange<Double>) -> some View { HStack { Text(title); Slider(value: bind(path), in: range); Text(String(format: "%.2f", store.theme[keyPath:path])).monospacedDigit().frame(width: 58, alignment: .trailing) } }
}

struct ColorField: View {
    let label: String; @Binding var value: String
    var body: some View { LabeledContent(label) { HStack { TextField("#RRGGBB", text: $value).font(.system(.body, design: .monospaced)).frame(width: 140); ColorPicker("", selection: Binding(get: { Color(nsColor: NSColor(themeHex:value) ?? .magenta) }, set: { value = NSColor($0).themeHex }), supportsOpacity: true).labelsHidden() } } }
}

struct ThemePreview: View {
    let theme: Theme
    private var accent: Color { color(theme.colors.accent) }
    private var panel: Color { color(theme.colors.panel) }
    private var text: Color { color(theme.colors.panelText) }
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black.opacity(0.88), color(theme.colors.backdrop)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: CGFloat(theme.geometry.itemSpacing)) {
                Text(theme.name.uppercased()).font(.system(size: theme.font.captionSize, weight: .semibold, design: .rounded)).foregroundStyle(accent).padding(.bottom, 12)
                ForEach(Array(["STATUS", "ITEMS", "SKILLS", "SETTINGS"].enumerated()), id: \.offset) { index,label in
                    HStack { Circle().fill(index == 1 ? Color.white : color(theme.colors.iconBadge)).frame(width: 11); Text(label); Spacer() }
                        .padding(.horizontal, 14).frame(width: theme.geometry.itemWidth, height: theme.geometry.itemHeight)
                        .background(index == 1 ? accent : panel, in: RoundedRectangle(cornerRadius: theme.geometry.cornerRadius))
                        .foregroundStyle(index == 1 ? color(theme.colors.accentText) : text)
                        .overlay(RoundedRectangle(cornerRadius: theme.geometry.cornerRadius).stroke(index == 1 ? accent : color(theme.colors.panelBorder), lineWidth: theme.effects.borderWidth))
                        .shadow(color: index == 1 ? accent.opacity(theme.effects.glowOpacity) : .black.opacity(theme.effects.shadowOpacity), radius: index == 1 ? theme.effects.selectedGlow : theme.effects.shadowRadius)
                }
                HStack(spacing: theme.geometry.circleSpacing) { ForEach(["star.fill","bolt.fill","gearshape.fill"], id: \.self) { Image(systemName:$0).frame(width:theme.geometry.circleDiameter,height:theme.geometry.circleDiameter).background(color(theme.colors.circle), in:Circle()).foregroundStyle(accent).overlay(Circle().stroke(color(theme.colors.circleBorder), lineWidth: theme.effects.borderWidth)) } }.padding(.top, 18)
            }.padding(28)
        }.clipShape(RoundedRectangle(cornerRadius: 12)).padding(16)
    }
    private func color(_ hex: String) -> Color { Color(nsColor: NSColor(themeHex:hex) ?? .magenta) }
}
