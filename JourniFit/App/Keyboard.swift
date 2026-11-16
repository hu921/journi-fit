import SwiftUI
import UIKit

/// Closes the keyboard when the user taps anywhere outside a text field.
/// Uses a window-level tap that does not block buttons or other taps.
final class KeyboardDismisser: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismisser()
    private weak var window: UIWindow?

    func install() {
        guard window == nil,
              let window = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first
        else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
        self.window = window

        // Number fields: select the current value when editing starts,
        // so typing replaces it (0 or last weight) instead of adding to it.
        NotificationCenter.default.addObserver(
            forName: UITextField.textDidBeginEditingNotification, object: nil, queue: .main
        ) { note in
            guard let field = note.object as? UITextField,
                  [.decimalPad, .numberPad].contains(field.keyboardType) else { return }
            DispatchQueue.main.async { field.selectAll(nil) }
        }
    }

    @objc private func tapped() {
        window?.endEditing(true)
    }

    // Ignore taps that land on a text field, so tapping into a field still works.
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let v = view {
            if v is UITextField || v is UITextView { return false }
            view = v.superview
        }
        return true
    }

    func gestureRecognizer(_ g: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

extension View {
    /// Installs the tap-anywhere keyboard dismiss once the window exists.
    func dismissKeyboardOnTap() -> some View {
        onAppear { DispatchQueue.main.async { KeyboardDismisser.shared.install() } }
    }

    /// Adds a Done button above number pads, which have no Return key.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }.bold()
            }
        }
    }
}
