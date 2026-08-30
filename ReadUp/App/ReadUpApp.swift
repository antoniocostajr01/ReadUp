//
//  ReadUpApp.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

@main
struct ReadUpApp: App {

    @State private var authManager = AuthManager()
    @State private var searchViewModel = SearchViewModel()
    @State private var libraryStore = LibraryStore()

    /// Barra de abas ink com itens em creme.
    ///
    /// Tem que ser aqui, e não no `init()` da `TabBar`: `UITabBar.appearance()` só
    /// vale pras barras criadas *depois* do proxy ser setado, e o SwiftUI reinicializa
    /// a struct da View quando quer — às vezes já com a UITabBar de pé. Daí a barra
    /// saía ora ink, ora vidro claro, com o mesmo código. O `init()` da App roda uma
    /// vez, antes de existir qualquer UI.
    ///
    /// Feito por `UITabBarAppearance` e não por `.toolbarBackground(_:for: .tabBar)`
    /// (ignorado no iOS 26) nem por `.tint()` (tinge a cápsula de vidro inteira).
    ///
    /// ponytail: o fundo ink só pega porque o `Info.plist` tem
    /// `UIDesignRequiresCompatibility`, que tira o app inteiro do Liquid Glass. Sem
    /// isso a barra de vidro do iOS 26 ignora `backgroundColor` (as cores dos itens
    /// pegam, o fundo não) e o ink chega na tela como `#6e695e`. A chave é uma saída
    /// temporária da Apple: quando ela sumir, ou a barra vira vidro e o fundo ink se
    /// perde, ou a pílula do Figma volta como view customizada.
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Palette.ink)
        appearance.shadowColor = .clear
        appearance.selectionIndicatorTintColor = UIColor(Palette.inkInverse.opacity(0.16))

        let cream = UIColor(Palette.inkInverse)
        let dimmed = UIColor(Palette.inkInverse.opacity(0.45))
        for layout in [appearance.stackedLayoutAppearance,
                       appearance.inlineLayoutAppearance,
                       appearance.compactInlineLayoutAppearance] {
            layout.normal.iconColor = dimmed
            layout.normal.titleTextAttributes = [.foregroundColor: dimmed]
            layout.selected.iconColor = cream
            layout.selected.titleTextAttributes = [.foregroundColor: cream]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
                .environment(searchViewModel)
                .environment(libraryStore)
                .background(.surface)
        }
    }
}
