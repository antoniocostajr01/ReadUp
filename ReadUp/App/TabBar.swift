//
//  TabBar.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct TabBar: View {
    @Environment(AuthManager.self) private var authManager
    @State private var selection: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var libraryPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    /// Compartilhado com as três abas: uma tela cheia aninhada sem passar pela
    /// `NavigationStack` (o detalhe da Library, trocado por dentro num `ZStack`) avisa
    /// por aqui que quer sumir com a pílula, já que nesse caso a pílula não sai sozinha.
    @State private var tabBarVisibility = TabBarVisibility()

    enum AppTab: Hashable { case home, library, profile }

    private let pillHeight: CGFloat = 62

    var body: some View {
        TabView(selection: $selection) {
            Tab(Localization.Tab.home.string, systemImage: "house", value: .home) {
                NavigationStack(path: $homePath) {
                    // A pílula fica presa à raiz de cada aba, não à `TabView` inteira:
                    // um push de verdade (`navigationDestination`) tira a raiz de cena
                    // sozinho, e a pílula (colada nela) some junto — de graça, sem
                    // precisar avisar nada. Colada na `TabView` de fora, ela ficaria
                    // por cima de qualquer tela empurrada.
                    ZStack(alignment: .bottom) {
                        gated(Home(), icon: "house.fill", title: Localization.Tab.home.string)
                            .tabBarClearance(pillHeight)
                        pill
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }

            Tab(Localization.Tab.library.string, systemImage: "books.vertical", value: .library) {
                NavigationStack(path: $libraryPath) {
                    ZStack(alignment: .bottom) {
                        gated(Library(), icon: "books.vertical.fill", title: Localization.Tab.library.string)
                            .tabBarClearance(pillHeight)
                        pill
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }

            Tab(Localization.Tab.profile.string, systemImage: "person", value: .profile) {
                NavigationStack(path: $profilePath) {
                    ZStack(alignment: .bottom) {
                        gated(Profile(), icon: "person.fill", title: Localization.Tab.profile.string)
                            .tabBarClearance(pillHeight)
                        pill
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .environment(tabBarVisibility)
    }

    // MARK: - Pílula

    @ViewBuilder
    private var pill: some View {
        if !tabBarVisibility.isHidden {
            pillContent
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var pillContent: some View {
        HStack(spacing: 44) {
            tabButton(.home, selected: "house.fill", unselected: "house", label: Localization.Tab.home.string)
            tabButton(.library, selected: "books.vertical.fill", unselected: "books.vertical", label: Localization.Tab.library.string)
            tabButton(.profile, selected: "person.fill", unselected: "person", label: Localization.Tab.profile.string)
        }
        .padding(.horizontal, Spacing.xxl)
        .frame(height: pillHeight)
        .background(Palette.surfaceChrome, in: .capsule)
        .padding(.bottom, Spacing.sm)
    }

    private func tabButton(_ tab: AppTab, selected: String, unselected: String, label: String) -> some View {
        Button {
            if selection == tab {
                // Comportamento nativo: tocar na aba já selecionada volta ao topo da
                // pilha de navegação em vez de não fazer nada.
                withAnimation(Motion.fast) { resetPath(tab) }
            } else {
                selection = tab
            }
        } label: {
            Image(systemName: selection == tab ? selected : unselected)
                .font(.system(size: 22))
                .foregroundStyle(selection == tab ? Palette.inkInverse : Palette.inkInverse.opacity(0.45))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }

    private func resetPath(_ tab: AppTab) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .library: libraryPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }

    /// Mostra a tela se autenticado, ou a parede de login se convidado.
    @ViewBuilder
    private func gated<Content: View>(_ content: Content, icon: String, title: String) -> some View {
        if authManager.isGuest {
            SignInRequiredView(
                icon: icon,
                title: Localization.Auth.guestWallTitle.string,
                message: Localization.Auth.guestWallMessage.string
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            content
        }
    }
}

/// Reserva o espaço que a barra nativa reservava sozinha. Aplicado dentro de cada
/// `NavigationStack`, direto no conteúdo da tela — colado na `TabView` de fora
/// (como `.safeAreaInset` tentou primeiro) não chegava até o `ScrollView` de cada
/// aba, e o fim da lista ficava atrás da cápsula flutuante.
///
/// Some junto com a pílula (lê o mesmo `TabBarVisibility`): sem isto, o detalhe da
/// Library — que esconde a pílula por dentro do próprio `ZStack` — continuava com o
/// vão vazio no rodapé reservado pra uma pílula que não estava mais lá.
private struct TabBarClearance: ViewModifier {
    @Environment(TabBarVisibility.self) private var tabBarVisibility
    let pillHeight: CGFloat

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: tabBarVisibility.isHidden ? 0 : pillHeight + Spacing.lg)
        }
    }
}

private extension View {
    func tabBarClearance(_ pillHeight: CGFloat) -> some View {
        modifier(TabBarClearance(pillHeight: pillHeight))
    }
}

/// Sinal para uma tela cheia aninhada (que não é um push de `NavigationStack`) dizer
/// que quer a pílula fora — a Library troca pro detalhe do livro por dentro do próprio
/// `ZStack`, então a raiz da aba continua "em cena" do ponto de vista da `NavigationStack`
/// e a pílula, colada nela, não sai sozinha.
@Observable
final class TabBarVisibility {
    var isHidden = false
}
