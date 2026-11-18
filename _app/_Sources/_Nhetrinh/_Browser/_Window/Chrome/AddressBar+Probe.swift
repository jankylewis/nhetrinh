import AppKit
import NhetrinhCore

/// P11-HISTORY (R54): the readback probe types in the address field as a user does (the field editor's own
/// text input, so the dropdown opens through `controlTextDidChange`) and presses its keys through the field
/// editor's commands. ⇧⌫ goes straight to the dropdown's command with shift down: the probe sends no event.
extension BrowserWindowController {
    static let addressKeys: [String: Selector] = [
        "Down": #selector(NSResponder.moveDown(_:)), "Up": #selector(NSResponder.moveUp(_:)),
        "Return": #selector(NSResponder.insertNewline(_:)), "Escape": #selector(NSResponder.cancelOperation(_:)),
        "Shift-Delete": #selector(NSResponder.deleteBackward(_:)),
    ]

    /// `.type` and `.key`, as a user types and presses them in the address field.
    func addressAnswer(_ request: ProbeRequest) -> ProbeResponse {
        let field = toolbar.address
        switch request {
        case .type(let text):
            guard window?.makeFirstResponder(field) == true, let editor = field.currentEditor() as? NSTextView else {
                return .failed("the address field took no focus in its window")
            }
            editor.selectAll(nil)
            editor.insertText(text, replacementRange: editor.selectedRange())
            return .done
        case .key(let name):
            guard let selector = Self.addressKeys[name] else { return .failed("no address key \(name)") }
            guard let editor = field.currentEditor() as? NSTextView else {
                return .failed("\(name): the address field is not being typed in")
            }
            if name == "Shift-Delete" {
                return toolbar.command(selector, shift: true) ? .done : .failed("Shift-Delete: no chosen row")
            }
            editor.doCommand(by: selector)
            return .done
        default: return .failed("not an address bar request")
        }
    }

    /// The dropdown as it reads now: its rows ([] when closed) and the chosen one.
    func readSuggestions(into state: inout ProbeState) {
        let list = toolbar.suggestions
        state.suggestions = list.isOpen ? list.shownRows : []
        state.suggestionChosen = list.isOpen ? list.chosen : nil
    }
}
