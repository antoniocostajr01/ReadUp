//
//  Library.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct Library: View {
    @EnvironmentObject private var tabState: AppTabState
    @Environment(LibraryStore.self) private var store

    private var books: [Book] { store.books }

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
        .navigationTitle(Localization.Library.title.string)
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
                .presentationDragIndicator(.visible)
        }
        .background(.backgroundPrimary)
    }
    
    private var libraryList: some View {
        List {
            ForEach(booksByStatus, id: \.status) { section in
                Section(section.status.displayName) {
                    ForEach(section.items) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            HStack(spacing: 12) {
                                LibraryCoverView(book: book)
                                
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
                
                Text(Localization.Library.emptyTitle.string)
                    .font(.system(.title2, weight: .bold))
                
                Text(Localization.Library.emptySubtitle.string)
                    .font(.body)
                    .foregroundStyle(.secundaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
        }
    }
    
}

#Preview {
    NavigationStack {
        Library()
            .environmentObject(AppTabState())
            .environment(LibraryStore())
    }
}
