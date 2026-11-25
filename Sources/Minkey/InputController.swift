import AppKit
import InputMethodKit
import MinkeyKit

/// One delivery for all clients, so each app's detected mode is remembered across fields. InputMethodKit calls the
/// controller only on the main thread, but its headers don't say so to Swift.
nonisolated(unsafe) let delivery = Delivery()

@objc(MinkeyInputController)
final class InputController: IMKInputController {
    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask.keyDown.rawValue)
    }

    override func activateServer(_ sender: Any!) {
        guard let client = sender as? any IMKTextInput else { return }
        delivery.activate(IMKTextClient(client))
    }

    override func deactivateServer(_ sender: Any!) {
        guard let client = sender as? any IMKTextInput else { return }
        delivery.deactivate(IMKTextClient(client))
    }

    override func commitComposition(_ sender: Any!) {
        guard let client = sender as? any IMKTextInput else { return }
        delivery.deactivate(IMKTextClient(client))
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, event.type == .keyDown, let client = sender as? any IMKTextInput else { return false }
        let key = Self.key(for: event)
        return delivery.handle(key, client: IMKTextClient(client))
    }

    private static let deleteKeyCode: UInt16 = 51

    static func key(for event: NSEvent) -> Key {
        if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty { return .boundary(nil) }
        if event.keyCode == deleteKeyCode { return .delete }
        guard let characters = event.characters, characters.count == 1, let character = characters.first else {
            return .boundary(nil)
        }
        if character.isASCII, character.isLetter { return .letter(character) }
        let isPrintable = character.unicodeScalars.allSatisfy {
            !CharacterSet.controlCharacters.contains($0) && !(0xF700...0xF8FF).contains($0.value)
        }
        return .boundary(isPrintable ? character : nil)
    }
}
