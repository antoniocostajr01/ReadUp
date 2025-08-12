//
//  TabBar.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct TabBar: View {
    @State private var selectedTab = 0
    @State private var isTabBarHidden = false
    
    var body: some View{

        switch selectedTab {
        case 0:
            NavigationStack{
                Home()
            }
        case 1:
            NavigationStack{
                Library()
            }
        case 2:
            NavigationStack{
                Profile()
            }
        default:
            Text("Unknown Tab")
        }
        
        HStack{
            Spacer()
            Button(action: {selectedTab = 0}) {
                
                VStack(spacing:6) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(selectedTab == 0 ? .emphasis : .secundaryLabel )
                    
                    Text("Home")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(selectedTab == 0 ? .emphasis : .secundaryLabel)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 13)
            Spacer()
            
            
            Button(action: {selectedTab = 1}) {
                
                VStack(spacing:6) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(selectedTab == 1 ? .emphasis : .secundaryLabel)
                    
                    Text("Library")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(selectedTab == 1 ? .emphasis : .secundaryLabel)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 13)
            Spacer()
            
            
            Button(action: {selectedTab = 2}) {
                
                VStack(spacing:6) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(selectedTab == 2 ? .emphasis : .secundaryLabel)
                    
                    Text("Profile")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(selectedTab == 2 ? .emphasis : .secundaryLabel)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 13)
            Spacer()
            
        }
        .background(
            RoundedRectangle(cornerRadius: 50)
                .foregroundStyle(.tabBarBackground)
                .frame(width: 361)
                .shadow(radius: 4, x:5, y: 10)
        )
        .padding(.bottom)
    }
}

#Preview {
    TabBar()
}
