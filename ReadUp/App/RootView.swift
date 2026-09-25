import SwiftUI

/// Decide o que mostrar com base no estado de autenticação:
/// logado → app completo (TabBar); deslogado → fluxo de login.
struct RootView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SearchViewModel.self) private var searchViewModel
    @Environment(LibraryStore.self) private var libraryStore
    @State private var isPreloading = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var availableUpdate: AvailableUpdate?
    /// Quando o aviso de atualização apareceu pela última vez (segundos desde 1970).
    @AppStorage("lastUpdatePromptDate") private var lastUpdatePromptDate: Double = 0

    var body: some View {
        Group {
            if authManager.phase == .loading || (authManager.phase == .ready && isPreloading) {
                LoadingView()
                    .task(id: authManager.phase) {
                        if authManager.phase == .ready {
                            let chosenGenres = GenreCatalog.genres(for: authManager.genres)
                            async let library: () = libraryStore.load()
                            async let discover: () = searchViewModel.loadDiscoverBooksIfNeeded()
                            async let sections: () = searchViewModel.loadSections(for: chosenGenres)
                            _ = await (library, discover, sections)

                            withAnimation {
                                isPreloading = false
                            }
                        }
                    }
            } else {
                switch authManager.phase {
                case .unauthenticated:
                    NavigationStack {
                        // O tour entra antes da Welcome e some depois de visto —
                        // a própria `OnboardingTour` decide qual das duas mostrar.
                        OnboardingTour()
                    }
                case .guest:
                    TabBar()
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
        // Toda vez que o app abre ou volta ao primeiro plano, no máximo uma vez por dia.
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task { await checkForUpdate() }
        }
        .alert(
            Localization.Generic.updateTitle.string,
            isPresented: Binding(
                get: { availableUpdate != nil },
                set: { if !$0 { availableUpdate = nil } }
            ),
            presenting: availableUpdate
        ) { update in
            Button(Localization.Generic.updateAction.string) { openURL(update.storeURL) }
            Button(Localization.Generic.notNow.string, role: .cancel) {}
        } message: { _ in
            Text(Localization.Generic.updateMessage.string)
        }
        .onChange(of: authManager.phase) { _, newPhase in
            if newPhase == .unauthenticated || newPhase == .guest || newPhase == .loading {
                isPreloading = true
            }
            // Logout/convidado: zera os dados em memória do usuário anterior.
            if newPhase == .unauthenticated || newPhase == .guest {
                libraryStore.reset()
            }
        }
    }

    /// Aviso opcional: o usuário pode ignorar, e só é lembrado de novo no dia seguinte.
    private func checkForUpdate() async {
        let now = Date().timeIntervalSince1970
        guard availableUpdate == nil, now - lastUpdatePromptDate > 24 * 60 * 60 else { return }
        guard let update = await AppUpdateService().availableUpdate() else { return }
        lastUpdatePromptDate = now
        availableUpdate = update
    }

    // Chave estável pra animar transições entre fases.
    private var phaseKey: Int {
        if isPreloading && (authManager.phase == .ready || authManager.phase == .loading) { return 1 }
        switch authManager.phase {
        case .unauthenticated: return 0
        case .guest: return 4
        case .loading: return 1
        case .onboarding: return 2
        case .ready: return 3
        }
    }
}

// O mesmo ambiente que o `ReadUpApp` monta: sem os três, a `RootView` rebenta ao
// resolver um `@Environment` que não existe — faltava aqui o `LibraryStore`.
#Preview {
    RootView()
        .environment(AuthManager())
        .environment(SearchViewModel())
        .environment(LibraryStore())
        .background(.surface)
        .preferredColorScheme(.light)
}
