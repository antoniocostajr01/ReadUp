//
//  BookDetails.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//
import SwiftData
import SwiftUI

struct BookDetails: View {
    
    @Query var books: [Book]
    @Query var sessions: [LiterarySession]
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var viewModel = BookDetailsViewModel()

    let book: Book
    
    var body: some View {
        VStack(spacing: 24){
            if let image = UIImage(data: book.imageData){
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 148 , height: 211)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            TitleAndAuthorBook(bookAuthor: book.author, bookTitle: book.title)
            
            Text("\(book.details)")
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 8){
                Image(systemName: "book.pages.fill")
                
                Text("\(book.numberOfPages)")
                
            }
            
            HStack{
                Text("\(book.status.rawValue)")
                    .foregroundStyle(.mainText)
                    .font(.system(.title3, weight: .semibold))
            }
            .frame(width: 297, height: 61)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.emphasis, lineWidth: 2)
            )
            .padding(.top, 24)
        }
        .frame(maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        viewModel.isShowingAlert.toggle()
                    } label: {
                        Label("Delete Book", systemImage: "trash.fill")
                    }
                    
                    Button{
                        viewModel.isShowingActionSheet = true
                        
                    } label: {
                        Label("Change Status", systemImage: "arrow.trianglehead.2.clockwise")
                    }

                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .background(.backgroundPrimary)
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea()
        .confirmationDialog("Select a status to this book", isPresented: $viewModel.isShowingActionSheet){
            ForEach(BookStatus.allCases, id: \.self){enumStatus in
                Button(enumStatus.rawValue){
                    book.status = enumStatus
                }
            }
            
        }
        .alert("Are you sure you want to delete this book?", isPresented: $viewModel.isShowingAlert) {
            Button("Delete", role: .destructive) {
                do {
                    try viewModel.deleteBook(book, context: modelContext)
                    dismiss()
                } catch {
                    print("Falha ao deletar as sessões: \(error.localizedDescription)")
                }

            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your book and your progress will be deleted.")
        }

    }
    
}
//
//#Preview {
//    BookDetails(book: <#Book#>)
//}
