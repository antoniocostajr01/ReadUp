import Foundation
import AuthenticationServices

/// Fase atual da sessão — dirige o que o `RootView` mostra.
enum SessionPhase {
    case unauthenticated   // primeiro uso, ainda não viu o Welcome → Welcome
    case guest             // navegando sem conta → TabBar (com features travadas)
    case loading           // carregando infos do usuário → LoadingView (verde)
    case onboarding        // logado mas sem gêneros → seleção de gostos
    case ready             // tudo pronto → TabBar
}

/// Fonte única de verdade da sessão de autenticação.
/// Mantém o usuário logado, o token (no Keychain), os gêneros e a fase do fluxo.
@MainActor
@Observable
final class AuthManager {

    var phase: SessionPhase = .unauthenticated
    var currentUser: AuthUser?
    var genres: [String] = []
    var isLoading: Bool = false      // spinner inline dos botões de auth
    var errorMessage: String?

    /// `true` quando há uma conta logada (exclui convidado e primeiro uso).
    var isAuthenticated: Bool {
        switch phase {
        case .unauthenticated, .guest: return false
        case .loading, .onboarding, .ready: return true
        }
    }

    /// `true` quando o usuário está navegando sem conta.
    var isGuest: Bool {
        if case .guest = phase { return true }
        return false
    }

    private let service = AuthService()
    private let hasSeenWelcomeKey = "hasSeenWelcome"
    private let hasLaunchedKey = "hasLaunchedBefore"

    private var token: String? {
        KeychainHelper.read(KeychainKey.authToken)
    }

    init() {
        // Primeiro lançamento após instalar: o UserDefaults vem zerado, mas o Keychain
        // sobrevive à reinstalação — pode haver um token antigo que pularia o Welcome.
        // Limpamos tudo para garantir que o primeiro acesso sempre comece no onboarding.
        if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
            KeychainHelper.delete(KeychainKey.authToken)
            UserDefaults.standard.removeObject(forKey: hasSeenWelcomeKey)
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
        }

        if token != nil {
            // Auto-login: há token salvo → carrega o perfil.
            phase = .loading
            Task { await bootstrap() }
        } else if UserDefaults.standard.bool(forKey: hasSeenWelcomeKey) {
            // Já passou pelo Welcome antes → entra direto como convidado.
            phase = .guest
        } else {
            // Primeiro uso → mostra o Welcome (onboarding).
            phase = .unauthenticated
        }
    }

    /// Entra no app sem conta (chamado pelo botão do Welcome).
    func enterGuestMode() {
        UserDefaults.standard.set(true, forKey: hasSeenWelcomeKey)
        phase = .guest
    }

    // MARK: - Bootstrap (carrega o perfil e decide a fase)

    /// Busca /users/me e decide entre onboarding (sem gêneros) e ready.
    func bootstrap() async {
        guard let token else {
            phase = .guest
            return
        }
        phase = .loading
        errorMessage = nil
        do {
            let user = try await service.fetchMe(token: token)
            currentUser = user
            genres = user.genres
            phase = user.genres.isEmpty ? .onboarding : .ready
        } catch AuthServiceError.unauthorized {
            // Token inválido/expirado → desloga.
            signOut()
        } catch AuthServiceError.notFound {
            // O usuário do token não existe mais (ex.: deletado no banco) → volta pro login.
            signOut()
        } catch {
            // Falha de rede → permite retry (LoadingView mostra o botão).
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Email / senha

    func signIn(email: String, password: String) async {
        await authenticate {
            try await self.service.login(email: email, password: password)
        }
    }

    func signUp(name: String, email: String, password: String) async {
        await authenticate {
            _ = try await self.service.register(name: name, email: email, password: password)
            return try await self.service.login(email: email, password: password)
        }
    }

    // MARK: - Apple

    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription

        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Could not read Apple credentials."
                return
            }

            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            await authenticate {
                try await self.service.loginWithApple(
                    identityToken: identityToken,
                    fullName: fullName.isEmpty ? nil : fullName,
                    email: credential.email
                )
            }
        }
    }

    // MARK: - Gêneros

    /// Salva os gêneros no backend e atualiza o estado local. Retorna sucesso.
    @discardableResult
    func updateGenres(_ newGenres: [String]) async -> Bool {
        guard let token else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let saved = try await service.updateGenres(newGenres, token: token)
            genres = saved
            currentUser?.genres = saved
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Conclui o onboarding de gêneros e entra no app.
    func completeOnboarding(with selected: [String]) async {
        if await updateGenres(selected) {
            phase = .ready
        }
    }

    // MARK: - Perfil (nome / foto)

    /// Atualiza o nome do usuário no backend e no estado local. Retorna sucesso.
    @discardableResult
    func updateName(_ newName: String) async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let token else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let updated = try await service.updateProfile(name: trimmed, avatar: nil, token: token)
            currentUser = updated
            genres = updated.genres
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Atualiza a foto de perfil (base64) no backend e no estado local. Retorna sucesso.
    @discardableResult
    func updateAvatar(_ base64: String) async -> Bool {
        guard let token else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let updated = try await service.updateProfile(name: nil, avatar: base64, token: token)
            currentUser = updated
            genres = updated.genres
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Remove a foto de perfil.
    @discardableResult
    func removeAvatar() async -> Bool {
        guard let token else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let updated = try await service.removeAvatar(token: token)
            currentUser = updated
            genres = updated.genres
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Forgot / Reset

    func requestPasswordReset(email: String) async -> Bool {
        await runReturningSuccess {
            try await self.service.forgotPassword(email: email)
        }
    }

    func confirmPasswordReset(email: String, code: String, newPassword: String) async -> Bool {
        await runReturningSuccess {
            try await self.service.resetPassword(email: email, code: code, newPassword: newPassword)
        }
    }

    // MARK: - Exclusão de conta

    /// Exclui a conta no backend e, em caso de sucesso, encerra a sessão local.
    /// Retorna `true` se a conta foi removida.
    @discardableResult
    func deleteAccount() async -> Bool {
        guard let token else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await service.deleteAccount(token: token)
            signOut()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Logout

    func signOut() {
        KeychainHelper.delete(KeychainKey.authToken)
        currentUser = nil
        genres = []
        errorMessage = nil
        // Após sair (ou excluir conta), o usuário continua navegando como convidado.
        UserDefaults.standard.set(true, forKey: hasSeenWelcomeKey)
        phase = .guest
    }

    // MARK: - Helpers privados

    /// Executa um fluxo de auth (login/signup/apple): valida credenciais → persiste →
    /// mostra o loading verde → carrega o perfil e decide a fase final.
    private func authenticate(_ action: @escaping () async throws -> AuthResponse) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await action()
            KeychainHelper.save(response.token, for: KeychainKey.authToken)
            currentUser = response.user
            genres = response.user.genres
            isLoading = false
            phase = .loading        // mostra a LoadingView verde
            await bootstrap()       // re-sincroniza o perfil e decide onboarding/ready
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func runReturningSuccess(_ action: @escaping () async throws -> Void) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await action()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
