//
//  Library.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI
import SwiftData

struct Library: View {
    
    @State private var searchText = ""
    @Query var books: [Book]

    var body: some View {
        NavigationStack{
            ScrollView{
    
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
                .padding(.top, 12)
                
            
                let uniqueStatus = Set(books.map { $0.status })
                
                ForEach(Array(uniqueStatus), id: \.self) {status in
                    VStack(alignment: .leading, spacing: 8){
                        Text(status.rawValue)
                            .font(.system(.title, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                        
                        HStack(spacing: 16){
                            ForEach(books.filter { $0.status == status }) {book in
                                if let uiImage = UIImage(data: book.imageData){
                                    VStack{
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .frame(width: 89, height: 127)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        
                                        Text("\(book.title)")
                                            .font(.callout)
                                            .lineLimit(1)
                                            .padding(.top, 4)
                                            .frame(width: 89)
                                    }
                                }
                            }

                        }
                        .padding(.top, 4)
                    }

                }
            }
            .padding(.leading,16)
            .padding(.trailing,16)
            .navigationTitle("Library")
            .background(.backgroundPrimary)
            .searchable(text: $searchText, prompt: "Search")
        }
    }

}

#Preview {
    Library()
}
