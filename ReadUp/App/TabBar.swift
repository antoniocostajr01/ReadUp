//
//  TabBar.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct TabBar: View {
    @Environment(AuthManager.self) private var authManager
    @State private var selectedTab = 0

    /// As abas visíveis dependem do modo: convidado troca Home/Library/Perfil pela
    /// parede de login, e ganha Busca.
    private var tabs: [ReadUpTabBar.Item] {
        var items: [ReadUpTabBar.Item] = [
            .init(tag: 0, icon: "house", title: Localization.Tab.home.string),
            .init(tag: 1, icon: "books.vertical", title: Localization.Tab.library.string),
        ]
        if authManager.isGuest {
            items.append(.init(tag: 2, icon: "magnifyingglass", title: Localization.Tab.search.string))
        }
        items.append(.init(tag: 4, icon: "person", title: Localization.Tab.profile.string))
        return items
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                gated(Home(), icon: "house.fill", title: Localization.Tab.home.string)
            }
            .tag(0)

            NavigationStack {
                gated(Library(), icon: "books.vertical.fill", title: Localization.Tab.library.string)
            }
            .tag(1)

            if authManager.isGuest {
                NavigationStack {
                    Search()
                }
                .tag(2)
            }

            NavigationStack {
                gated(Profile(), icon: "person.fill", title: Localization.Tab.profile.string)
            }
            .tag(4)
        }
        // A barra nativa é substituída pela pílula flutuante do design system.
        .toolbar(.hidden, for: .tabBar)
        // `safeAreaInset` reserva a altura da barra automaticamente, então nenhuma
        // tela precisa de padding próprio pra não ficar embaixo dela.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ReadUpTabBar(items: tabs, selection: $selectedTab)
        }
        .onAppear {
            // Convidado começa na busca (Home/Library/Perfil exigem conta).
            if authManager.isGuest { selectedTab = 2 }
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

// MARK: - The floating pill

/// The tab bar from the design system (Figma `37:296`).
///
/// *"A floating pill: 62pt tall, 31pt radius, ink at 94%, inset 20pt from each side
/// and 22pt from the bottom."* Active tab is cream; inactive is cream at low alpha.
/// It is the one piece of chrome that reads as ink rather than cream, which is what
/// keeps it separate from the content it floats over.
struct ReadUpTabBar: View {

    struct Item: Identifiable {
        let tag: Int
        /// An outline SF Symbol — the design uses thin glyphs, never filled ones.
        let icon: String
        let title: String

        var id: Int { tag }
    }

    let items: [Item]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isActive = item.tag == selection

                Button {
                    selection = item.tag
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .light))
                        Text(item.title)
                            .textStyle(.captionFine)
                    }
                    .foregroundStyle(isActive ? Palette.inkInverse : Palette.inkInverse.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
            }
        }
        .frame(height: Spacing.tabBarHeight)
        .background(
            Capsule(style: .continuous).fill(Palette.surfaceChrome)
        )
        .padding(.horizontal, Spacing.tabBarInset)
        .padding(.bottom, Spacing.sheetInset)
        .animation(Motion.fast, value: selection)
    }
}
