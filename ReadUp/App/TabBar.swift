//
//  TabBar.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct TabBar: View {
    @Environment(AuthManager.self) private var authManager
    @StateObject private var tabState = AppTabState()

    var body: some View {
        TabView(selection: $tabState.selectedTab) {
            NavigationStack{
                gated(Home(), icon: "house.fill", title: Localization.Tab.home.string)
            }
            .tabItem {
                Label(Localization.Tab.home.string, systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack{
                gated(Library(), icon: "books.vertical.fill", title: Localization.Tab.library.string)
            }
            .tabItem {
                Label(Localization.Tab.library.string, systemImage: "books.vertical.fill")
            }
            .tag(1)

            NavigationStack{
                Search()
            }
            .tabItem {
                Label(Localization.Tab.search.string, systemImage: "magnifyingglass")
            }
            .tag(2)

            NavigationStack{
                AI()
            }
            .tabItem {
                Label(Localization.Tab.ai.string, systemImage: "sparkles")
            }
            .tag(3)

            NavigationStack{
                gated(Profile(), icon: "person.fill", title: Localization.Tab.profile.string)
            }
            .tabItem {
                Label(Localization.Tab.profile.string, systemImage: "person.fill")
            }
            .tag(4)
        }
        .environmentObject(tabState)
        .onAppear {
            // Convidado começa na busca (Home/Library/Perfil exigem conta).
            if authManager.isGuest { tabState.selectedTab = 2 }
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

#Preview {
    TabBar()
        .environment(AuthManager())
        .environment(SearchViewModel())
}
