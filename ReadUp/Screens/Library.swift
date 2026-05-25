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
    
    @State private var selectedBook: Book?
    
    private var booksByStatus: [(status: BookStatus, items: [Book])] {
        let orderedStatuses = BookStatus.allCases.filter { status in
            books.contains(where: { $0.status == status })
        }
        
        return orderedStatuses.map { status in
            let items = books
                .filter { $0.status == status }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            return (status, items)
        }
    }
    
    var body: some View {
        Group {
            if books.isEmpty {
                emptyState
            } else {
                libraryList
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tabState.goToSearchTab()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $selectedBook) { book in
            BookDetailsSheet(source: .library(book))
        }
        .background(.backgroundPrimary)
    }
    
    private var libraryList: some View {
        List {
            ForEach(booksByStatus, id: \.status) { section in
                Section(section.status.rawValue) {
                    ForEach(section.items) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            HStack(spacing: 12) {
                                coverView(for: book)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title)
                                        .font(.headline)
                                        .foregroundStyle(Color(uiColor: .label))
                                        .lineLimit(2)
                                    
                                    Text(book.author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secundaryLabel)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.backgroundPrimary)
    }
    
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 14) {
                Spacer(minLength: 88)
                
                Image(systemName: "books.vertical")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(.emphasis)
                
                Text("No books yet")
                    .font(.system(.title2, weight: .bold))
                
                Text("Use Search to find books and add them to your library.")
                    .font(.body)
                    .foregroundStyle(.secundaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
        }
    }
    
    private func coverView(for book: Book) -> some View {
        Group {
            if let uiImage = UIImage(data: book.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(uiColor: .tertiarySystemFill)
            }
        }
        .frame(width: 44, height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, LiterarySession.self, configurations: config)

    let sample1 = Book(
        title: "The Hobbit",
        author: "J.R.R. Tolkien",
        numberOfPages: 310,
        details: "A fantasy classic.",
        status: .reading,
        imageData: Data()
    )

    let sample2 = Book(
        title: "Thinking, Fast and Slow",
        author: "Daniel Kahneman",
        numberOfPages: 499,
        details: "Psychology and decision making.",
        status: .iWantToRead,
        imageData: Data()
    )

    container.mainContext.insert(sample1)
    container.mainContext.insert(sample2)

    return NavigationStack {
        Library()
            .environmentObject(AppTabState())
    }
    .modelContainer(container)
}
