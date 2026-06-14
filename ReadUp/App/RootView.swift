import SwiftUI

/// Decide o que mostrar com base no estado de autenticação:
/// logado → app completo (TabBar); deslogado → fluxo de login.
struct RootView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SearchViewModel.self) private var searchViewModel
    @State private var isPreloading = true

    var body: some View {
        Group {
            if authManager.phase == .loading || (authManager.phase == .ready && isPreloading) {
                LoadingView()
                    .task(id: authManager.phase) {
                        if authManager.phase == .ready {
                            let chosenGenres = GenreCatalog.genres(for: authManager.genres)
                            async let discover: () = searchViewModel.loadDiscoverBooksIfNeeded()
                            async let sections: () = searchViewModel.loadSections(for: chosenGenres)
                            _ = await (discover, sections)
                            
                            withAnimation {
                                isPreloading = false
                            }
                        }
                    }
            } else {
                switch authManager.phase {
                case .unauthenticated:
                    NavigationStack {
                        WelcomeView()
                    }
                case .loading:
                    EmptyView()
                case .onboarding:
                    GenreOnboardingView()
                case .ready:
                    TabBar()
                }
            }
        }
        .animation(.easeInOut, value: phaseKey)
        .onChange(of: authManager.phase) { _, newPhase in
            if newPhase == .unauthenticated || newPhase == .loading {
                isPreloading = true
            }
        }
    }

    // Chave estável pra animar transições entre fases.
    private var phaseKey: Int {
        if isPreloading && (authManager.phase == .ready || authManager.phase == .loading) { return 1 }
        switch authManager.phase {
        case .unauthenticated: return 0
        case .loading: return 1
        case .onboarding: return 2
        case .ready: return 3
        }
    }
}

#Preview {
    RootView()
        .environment(AuthManager())
        .environment(SearchViewModel())
}
