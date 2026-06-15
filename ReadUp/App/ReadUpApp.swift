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
                .background(.backgroundPrimary)
        }
    }
}
