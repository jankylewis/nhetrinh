import AppKit

/// P8-FONT-1 (headmate request): the one font of the app's own interface, Menlo, at each control's own
/// point size. Web pages keep their own fonts: WebKit's default fonts are not touched. With no Menlo, the
/// system monospaced font. Every view lists its text controls (`textControls`); the probe reads the same.
enum AppFont {
    static let family = "Menlo"

    /// The font at `size`; `family` is a parameter only for the test of the fallback.
    static func font(size: CGFloat, bold: Bool = false, family: String = family) -> NSFont {
        let traits: NSFontTraitMask = bold ? .boldFontMask : []
        let found = NSFontManager.shared.font(withFamily: family, traits: traits, weight: bold ? 9 : 5, size: size)
        return found ?? .monospacedSystemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    /// Each control in the font, at the point size it has now.
    static func apply(to controls: [NSControl]) {
        for control in controls {
            control.font = font(size: control.font?.pointSize ?? NSFont.systemFontSize)
        }
    }

    /// The font family of `controls`: one name when they agree, else "mixed: " and every name; "" for none.
    /// Read by the probe (R47).
    static func family(of controls: [NSControl]) -> String {
        let names = Set(controls.compactMap { $0.font?.familyName })
        return names.count > 1 ? "mixed: " + names.sorted().joined(separator: ", ") : names.first ?? ""
    }

    /// Every control in `view` and below it.
    static func controls(in view: NSView) -> [NSControl] {
        ((view as? NSControl).map { [$0] } ?? []) + view.subviews.flatMap(controls(in:))
    }
}
