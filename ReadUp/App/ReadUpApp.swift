//
//  ReadUpApp.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI
import SwiftData

@main
struct ReadUpApp: App {

    @State private var authManager = AuthManager()
    @State private var searchViewModel = SearchViewModel()

    var body: some Scene {
        WindowGroup {
            RootView() 
                .environment(authManager)
                .environment(searchViewModel)
                .background(.backgroundPrimary)
        }
        .modelContainer(for: [Book.self,LiterarySession.self] )
    }
}


