---
name: auth-architecture
description: ReadUp auth flow — JWT, Keychain, AuthManager gate, Apple Sign In, password reset.
metadata:
  type: project
---

Autenticação do ReadUp (implementada 2026-06-13):

**iOS:**
- `AuthManager` (`@Observable @MainActor`) é a fonte única de verdade da sessão (`isAuthenticated`, `currentUser`). No `init` lê o token do Keychain → auto-login.
- `RootView` é o gate: `isAuthenticated` → `TabBar`, senão → `NavigationStack { LoginView }`. Injetado em `ReadUpApp` via `.environment`.
- Token JWT guardado no **Keychain** (`KeychainHelper`, key `readup.authToken`), não em UserDefaults.
- `AuthService` (struct, padrão do `BackendAIService`) faz as chamadas HTTP. Telas em `ReadUp/Views/Auth/`.
- "Continue with Apple" usa `SignInWithAppleButton`; manda o `identityToken` pro backend. **Requer a capability "Sign in with Apple" ativada no Xcode** (conta paga Apple Developer) — código compila sem ela, mas o botão só funciona depois de ativada. STATUS: capability ainda não ativada pelo usuário (pendente).

**Backend:** JWT assinado com `JWT_SECRET`, expira em 7 dias. `/auth/apple` valida o token da Apple contra as chaves públicas (lib `apple-signin-auth`, audience = `APPLE_CLIENT_ID`) e faz find-or-create por appleId→email. Reset de senha: código de 6 dígitos, salvo como hash bcrypt, expira em 15 min, uso único; `/auth/forgot-password` sempre responde 200 (anti-enumeração). Testado ponta a ponta e funcionando.

Hosting/env vars: ver [[infra-deploy]].
