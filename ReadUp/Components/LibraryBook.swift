//
//  LibraryBook.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import SwiftUI

struct LibraryBook: View {
    var cover: BookCover
        
    var body: some View {
        cover.image
            .resizable()
            .frame(width: 89, height: 127)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 8)
    }
}

#Preview {
    LibraryBook(cover: .rodrick)
}
