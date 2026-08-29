//
//  TitleAndAuthorBook.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import SwiftUI

struct TitleAndAuthorBook: View {
    @State var bookAuthor: String = "Title"
    @State var bookTitle: String = "Author"
    
    var body: some View {
        VStack{
            Text(bookTitle)
                .lineLimit(1)
                .font(.titleSecondary)
                .foregroundStyle(.ink)
            Text(bookAuthor)
                .font(.bodyDefault)
                .foregroundStyle(.inkMuted)
        }
    }
}

#Preview {
    TitleAndAuthorBook(bookAuthor:"George Orwell" , bookTitle: "1984")
}
