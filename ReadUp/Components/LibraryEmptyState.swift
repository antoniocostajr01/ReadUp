//
//  EmptyState.swift
//  ReadUp
//
//  Created by Antonio Costa on 09/10/25.
//

import SwiftUI

struct LibraryEmptyState: View {
    var title: String
    var details: String
    
    
    var body: some View {
        
        VStack(alignment: .center, spacing: Spacing.xxl){
                        
            VStack(alignment: .center, spacing: Spacing.sm){
                Text(title)
                    .font(Font.title.bold())
                
                Text(details)
                    .multilineTextAlignment(.center)
                
            }
        }
    }
}

#Preview {
    LibraryEmptyState(title: "No books yet!", details: "Ready to give your mind a new adventure? Add your first book and start your reading journey!")
}
