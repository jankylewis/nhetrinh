import AppKit

/// P11-HISTORY (D30): the address field's typing drives the dropdown (`SuggestionList`). Each change of the
/// text asks for rows; no work while the user does not type. ↑ ↓ choose, Return opens the chosen row (none
/// chosen: the field's own action, what was typed), Esc closes and keeps the text, ⇧⌫ removes the chosen row.
extension ToolbarView: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        suggestions.onTyping?(address.stringValue)
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        suggestions.close()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        command(selector, shift: NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false)
    }

    /// The field editor's command `selector`; true when the dropdown took it.
    @discardableResult
    func command(_ selector: Selector, shift: Bool) -> Bool {
        guard suggestions.isOpen else { return false }
        switch selector {
        case #selector(NSResponder.moveDown(_:)): suggestions.move(1)
        case #selector(NSResponder.moveUp(_:)): suggestions.move(-1)
        case #selector(NSResponder.cancelOperation(_:)): suggestions.close()
        case #selector(NSResponder.insertNewline(_:)):
            guard let row = suggestions.chosen else {
                suggestions.close()
                return false  // the field's action: what was typed, as before
            }
            suggestions.open(row)
        case #selector(NSResponder.deleteBackward(_:)) where shift:
            guard let row = suggestions.chosenRow else { return false }
            suggestions.onRemove?(row)
        default: return false
        }
        return true
    }
}

extension ToolbarView {
    /// The address field: one line, cut at the end (the field editor scrolls it while editing) (NT-BUG-030: a plain
    /// field wrapped a long address onto a second line that the bar cut in half).
    func setUpAddress() {
        address.placeholderString = "Search or enter address"
        address.bezelStyle = .roundedBezel
        address.focusRingType = .none
        address.usesSingleLineMode = true
        address.lineBreakMode = .byTruncatingTail
        address.cell?.wraps = false
        address.target = self
        address.action = #selector(submit)
        address.delegate = self
        address.setAccessibilityIdentifier("nhetrinh.address")
    }
}
