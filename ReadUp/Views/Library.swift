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
    @State private var searchText = ""
    @State private var isShowingAddManually = false

    /// Livros filtrados pela busca (título ou autor). Sem texto, retorna todos.
    private var filteredBooks: [Book] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.author.localizedCaseInsensitiveContains(query)
        }
    }

    private var booksByStatus: [(status: BookStatus, items: [Book])] {
        let source = filteredBooks
        let orderedStatuses = BookStatus.allCases.filter { status in
            source.contains(where: { $0.status == status })
        }

        return orderedStatuses.map { status in
            let items = source
                .filter { $0.status == status }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            return (status, items)
        }
    }

    var body: some View {
        content
        .navigationTitle(Localization.Library.title.string)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        tabState.goToSearchTab()
                    } label: {
                        Label(Localization.Library.searchOption.string, systemImage: "magnifyingglass")
                    }
                    Button {
                        isShowingAddManually = true
                    } label: {
                        Label(Localization.Library.addManually.string, systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $selectedBook) { book in
            BookDetailsSheet(source: .library(book))
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAddManually) {
            BookFormView(mode: .create)
        }
        .background(.backgroundPrimary)
    }

    /// Livraria vazia mostra o empty state; com livros, habilita a busca e mostra
    /// a lista (ou o estado "nada encontrado" quando a busca não retorna nada).
    @ViewBuilder
    private var content: some View {
        if books.isEmpty {
            emptyState
        } else {
            Group {
                if booksByStatus.isEmpty {
                    noResultsState
                } else {
                    libraryList
                }
            }
            .searchable(text: $searchText, prompt: Localization.Library.searchPrompt.string)
        }
    }

    private var noResultsState: some View {
        ContentUnavailableView {
            Label(Localization.Library.noResultsTitle.string, systemImage: "magnifyingglass")
        } description: {
            Text(Localization.Library.noResultsSubtitle.string)
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
