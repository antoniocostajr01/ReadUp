import AuthenticationServices
import SwiftUI

/// Dispara o fluxo "Sign in with Apple" a partir de um botão qualquer.
///
/// O `SignInWithAppleButton` do SwiftUI não pode ser restilizado, e as gambiarras
/// pra escondê-lo (opacidade quase zero por baixo de um botão nosso) deixam o
/// controle nativo vazando por trás. Aqui o fluxo é chamado direto pelo
/// `ASAuthorizationController`, então a aparência fica 100% no `ReadUpButton` e o
/// caminho de autenticação continua sendo o mesmo `authManager.signInWithApple`.
@MainActor
final class AppleSignInCoordinator: NSObject, ObservableObject {

    private var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?
    /// Mantém o controller vivo enquanto a folha da Apple está aberta.
    private var controller: ASAuthorizationController?

    func start(_ completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        onCompletion = completion

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        controller.performRequests()
    }

    private func finish(_ result: Result<ASAuthorization, Error>) {
        onCompletion?(result)
        onCompletion = nil
        controller = nil
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in finish(.success(authorization)) }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in finish(.failure(error)) }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            // A janela ativa da cena em primeiro plano — o app é single-window.
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }

            return scene?.keyWindow ?? scene?.windows.first ?? ASPresentationAnchor()
        }
    }
}
