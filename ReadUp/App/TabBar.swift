//
//  TabBar.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct TabBar: View {
    @StateObject private var tabState = AppTabState()
    
    var body: some View {
        TabView(selection: $tabState.selectedTab) {
            NavigationStack{
                Home()
            }
            .tabItem {
                Label(Localization.Tab.home.string, systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationStack{
                Library()
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
                Profile()
            }
            .tabItem {
                Label(Localization.Tab.profile.string, systemImage: "person.fill")
            }
            .tag(4)
        }
        .environmentObject(tabState)
    }
}

#Preview {
    TabBar()
        .environment(AuthManager())
        .environment(SearchViewModel())
}
