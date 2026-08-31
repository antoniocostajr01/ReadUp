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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
                .environment(searchViewModel)
                .environment(libraryStore)
                .background(.surface)
                // Editorial Cream não tem modo escuro. Sem isto, no aparelho em dark
                // mode todo `Text` sem `foregroundStyle` resolve pra branco e some no
                // creme — o ink dos tokens só vale onde a cor foi escrita à mão.
                .preferredColorScheme(.light)
        }
    }
}
