//
//  EmptyState.swift
//  ReadUp
//
//  Created by Antonio Costa on 09/10/25.
//

import SwiftUI

struct LibraryEmptyState: View {
    
    @State var showSheetNewBok: Bool = false
    
    var title: String
    var details: String
    
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 32){
                        
            VStack(alignment: .center, spacing: 8){
                Text(title)
                    .font(Font.title.bold())
                
                Text(details)
                    .multilineTextAlignment(.center)
                
            }
            
            NavigationLink(destination: AddNewBook()){
                HStack{
                    Text("Add new book")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.componentBackground)
                    Image(systemName: "plus")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.componentBackground)
                }
                .padding()
                .frame(width: 361, height: 61)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .foregroundStyle(.emphasis)
                )
            }
            
        }
    }
}

#Preview {
    LibraryEmptyState(title: "No books yet!", details: "Ready to give your mind a new adventure? Add your first book and start your reading journey!")
}
