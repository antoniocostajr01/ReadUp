//
//  TabBar.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

/// As três abas do app: a barra é a nativa do iOS, tingida de ink.
///
/// O Figma tem um componente `Chrome/Tab bar` (pílula flutuante), mas ele é
/// referência apenas — a barra nativa venceu. O que veio do Figma é o conjunto de
/// abas (Home, Library, Profile) e a cor de seleção.
struct TabBar: View {
    @Environment(AuthManager.self) private var authManager
    @State private var selection: AppTab = .home

    private enum AppTab: Hashable { case home, library, profile }

    var body: some View {
        TabView(selection: $selection) {
            Tab(Localization.Tab.home.string, systemImage: "house", value: .home) {
                NavigationStack {
                    gated(Home(), icon: "house.fill", title: Localization.Tab.home.string)
                }
            }

            Tab(Localization.Tab.library.string, systemImage: "books.vertical", value: .library) {
                NavigationStack {
                    gated(Library(), icon: "books.vertical.fill", title: Localization.Tab.library.string)
                }
            }

            Tab(Localization.Tab.profile.string, systemImage: "person", value: .profile) {
                NavigationStack {
                    gated(Profile(), icon: "person.fill", title: Localization.Tab.profile.string)
                }
            }
        }
        .tint(.ink)
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
