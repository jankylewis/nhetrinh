import ApplicationServices

/// One element of an app's accessibility tree: the same tree VoiceOver and Voice Control use.
/// Since D23 only R2 reads it, to find the Dock item of the app; it only reads, never acts.
/// R1, R3-R7 read and act on nhetrinh through its readback probe (`_Steps/Probe.swift`).
struct AXNode {
    let element: AXUIElement

    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func application(pid: pid_t) -> AXNode {
        AXNode(element: AXUIElementCreateApplication(pid))
    }

    private func raw(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    func nodes(_ name: String) -> [AXNode] { (raw(name) as? [AXUIElement] ?? []).map(AXNode.init) }
    func flag(_ name: String) -> Bool { raw(name) as? Bool ?? false }
    var url: URL? { raw(kAXURLAttribute) as? URL }
    var children: [AXNode] { nodes(kAXChildrenAttribute) }

    /// Position and size on screen, in points, origin at the top left.
    var frame: CGRect? {
        guard let position = raw(kAXPositionAttribute), let size = raw(kAXSizeAttribute),
              CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        var origin = CGPoint.zero, extent = CGSize.zero
        AXValueGetValue(position as! AXValue, .cgPoint, &origin)  // force: the CF type is checked above
        AXValueGetValue(size as! AXValue, .cgSize, &extent)  // force: the CF type is checked above
        return CGRect(origin: origin, size: extent)
    }
}
