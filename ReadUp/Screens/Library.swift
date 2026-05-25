//
//  Library.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI
import SwiftData

struct Library: View {
    @EnvironmentObject private var tabState: AppTabState
    @Query var books: [Book]

    @State var selectedBook: Book?
    
    var body: some View {
            VStack{
                addBookButton
                    .padding(.top, 12)

                if books.isEmpty {
                    LibraryEmptyState(title: "No books yet!", details: "Ready to give your mind a new adventure? Add your first book and start your reading journey!")
                } else {
                    ScrollView{

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
                                            .onTapGesture{
                                                selectedBook = book
                                            }
                                        }
                                    }
                                    
                                }
                                .padding(.top, 4)
                            }
                            
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal,16)
            .sheet(item: $selectedBook ){ book in
                NavigationStack{
                    BookDetails(book: book)
                        .presentationDragIndicator(.visible)
                        .background(.backgroundPrimary)

                }
            }
            .navigationTitle("Library")
            .background(.backgroundPrimary)
        
    }

    private var addBookButton: some View {
        Button {
            tabState.goToSearchTab()
        } label: {
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

#Preview {
    Library()
}
