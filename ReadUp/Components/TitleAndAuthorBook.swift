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
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(.mainText)
            Text(bookAuthor)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secundaryLabel)
        }
    }
}

#Preview {
    TitleAndAuthorBook(bookAuthor:"George Orwell" , bookTitle: "1984")
}
