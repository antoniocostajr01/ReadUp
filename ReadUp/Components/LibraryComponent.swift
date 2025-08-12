//
//  LibraryComponent.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import SwiftUI
import SwiftData


struct LibraryComponent: View {
    
    @Query private var books: [Book]
    var title: String
    var covers: [BookCover]
    
    var body: some View {
        
        
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .multilineTextAlignment(.leading)
            .foregroundStyle(.mainText)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        
        ScrollView(.horizontal){
            HStack(spacing: 16){
                ForEach(covers, id: \.self) { cover in
                    LibraryBook(cover: cover)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    LibraryComponent(title: "Toninho gameplay", covers: [._1984, .hobbit])
}
