//
//  BookDetails.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//
import SwiftUI

struct BookDetails: View {

    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) var dismiss

    @State private var viewModel = BookDetailsViewModel()

    let book: Book

    /// Reflete o estado mais recente do livro no store (ex.: após mudar status).
    private var currentBook: Book {
        store.books.first { $0.id == book.id } ?? book
    }

    var body: some View {
        VStack(spacing: 24){
            BookCoverView(coverUrl: currentBook.coverUrl, width: 148, height: 211, cornerRadius: 12)

            TitleAndAuthorBook(bookAuthor: currentBook.author, bookTitle: currentBook.title)

            Text("\(currentBook.details)")
                .frame(maxWidth: .infinity)

            HStack(spacing: 8){
                Image(systemName: "book.pages.fill")

                Text("\(currentBook.numberOfPages)")

            }

            HStack{
                Text(currentBook.status.displayName)
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
                        viewModel.isShowingDeleteAlert.toggle()
                    } label: {
                        Label(Localization.BookDetails.deleteBook.string, systemImage: "trash.fill")
                    }
                    
                    Button{
                        viewModel.isShowingStatusDialog = true
                        
                    } label: {
                        Label(Localization.BookDetails.changeStatus.string, systemImage: "arrow.triangle.2.circlepath")
                    }

                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .background(.backgroundPrimary)
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea()
        .confirmationDialog(Localization.BookDetails.selectStatus.string, isPresented: $viewModel.isShowingStatusDialog){
            ForEach(BookStatus.allCases, id: \.self){ enumStatus in
                Button(enumStatus.displayName){
                    Task { await store.updateStatus(currentBook, to: enumStatus) }
                }
            }

        }
        .alert(Localization.BookDetails.deleteConfirmTitle.string, isPresented: $viewModel.isShowingDeleteAlert) {
            Button(Localization.Generic.delete.string, role: .destructive) {
                Task {
                    await store.deleteBook(currentBook)
                    dismiss()
                }
            }
            Button(Localization.Generic.cancel.string, role: .cancel) {}
        } message: {
            Text(Localization.BookDetails.deleteConfirmMessage.string)
        }

    }
    
}

