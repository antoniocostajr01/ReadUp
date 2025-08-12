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
    
    var body: some Scene {
        WindowGroup {
            TabBar()
                .background(.backgroundPrimary)
        }
        .modelContainer(for: [Book.self,LiterarySession.self] )
    }
}


