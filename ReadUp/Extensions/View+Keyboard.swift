import SwiftUI

extension View {
    /// Fecha o teclado resignando o first responder ativo.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
