---
name: onboarding-preferences
description: ReadUp onboarding flow (intro + falling-genre picker) and per-user genre preferences.
metadata:
  type: project
---

Onboarding e preferências de gênero (implementado 2026-06-13):

**Fluxo (gate por fases em `AuthManager.phase`: unauthenticated/loading/onboarding/ready, lido pelo `RootView`):**
- Deslogado → `WelcomeView` (carrossel multi-página de intro, dots + Next/Back/Skip) → `LoginView`.
- Após login e em todo launch com token → `LoadingView` (tela verde com livro `book.closed.fill` saltando+girando) enquanto `AuthManager.bootstrap()` chama `GET /users/me`.
- Logado **sem gêneros** → `GenreOnboardingView` (SpriteKit: `GenrePhysicsScene` com chips de gênero caindo/empilhando; tocar seleciona; "Continue" salva e vai pro app). Com ≥1 gênero salvo, nunca reaparece.

**Gêneros:**
- Catálogo único em `ReadUp/Models/GenreCatalog.swift` (`Genre`: title/query/icon), reusado por onboarding, Search e Profile. O `title` é o valor salvo no backend.
- Backend: campo `User.genres String[]`. Endpoints autenticados `GET /users/me` e `PUT /users/me/genres` (Bearer token). Auth responses (login/apple) já incluem `genres`.
- iOS: `AuthService.fetchMe/updateGenres` (mandam `Authorization: Bearer <token>` do Keychain). `AuthManager.genres` é a fonte de verdade; `updateGenres()`/`completeOnboarding()`.
- **Search** (`SearchViewModel.loadSections`): estado padrão = um carrossel por gênero escolhido (`authManager.genres`), com cache por gênero; reage a add/remover via `.onChange(of: authManager.genres)`. Sem gêneros → fallback discover.
- **Profile**: seção "Your genres" com chips (remover via x) + menu "Add"; persiste via `authManager.updateGenres`.

Relacionado: [[auth-architecture]], [[infra-deploy]].
