//
//  Library.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct Library: View {
    @Environment(LibraryStore.self) private var store

    private var books: [Book] { store.books }

    @State private var selectedBook: Book?
    @State private var searchText = ""
    private enum AddOption { case scan, search, manual }

    @State private var isShowingAddOptions = false
    @State private var pendingOption: AddOption?
    @Namespace private var addButtonNamespace
    @State private var isShowingScanner = false
    @State private var isShowingSearch = false
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
                Button {
                    isShowingAddOptions = true
                } label: {
                    Image(systemName: "plus")
                }
                // O modal cresce a partir do próprio "+", em vez de subir do rodapé.
                .matchedTransitionSource(id: "addBook", in: addButtonNamespace)
            }
        }
        // A tela escolhida abre no onDismiss, não no toque: apresentar uma sheet enquanto
        // outra ainda está saindo faz o SwiftUI engolir a segunda.
        .sheet(isPresented: $isShowingAddOptions, onDismiss: openPendingOption) {
            addOptionsSheet
                .navigationTransition(.zoom(sourceID: "addBook", in: addButtonNamespace))
        }
        .sheet(item: $selectedBook) { book in
            BookDetailsSheet(source: .library(book))
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            ISBNScanView()
        }
        .sheet(isPresented: $isShowingSearch) {
            NavigationStack {
                Search()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isShowingSearch = false
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            .accessibilityLabel(Localization.Generic.done.string)
                        }
                    }
            }
        }
        .sheet(isPresented: $isShowingAddManually) {
            BookFormView(mode: .create)
        }
        .background(.surface)
    }

    // MARK: - Modal de adicionar livro

    private var addOptionsSheet: some View {
        VStack(spacing: Spacing.md) {
            Text(Localization.BookDetails.addToLibrary.string)
                .font(.titleSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, Spacing.xs)

            addOptionRow(Localization.Library.scan.string, icon: "barcode.viewfinder", option: .scan)
            addOptionRow(Localization.Library.searchOption.string, icon: "magnifyingglass", option: .search)
            addOptionRow(Localization.Library.addManually.string, icon: "square.and.pencil", option: .manual)

            Spacer()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Sem cor de fundo opaca: o vidro do sistema deixa a biblioteca aparecer atrás,
        // que é o que dá a leitura de "camada por cima" em vez de tela preta nova.
        .presentationBackground(.regularMaterial)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
    }

    private func addOptionRow(_ title: String, icon: String, option: AddOption) -> some View {
        Button {
            pendingOption = option
            isShowingAddOptions = false
        } label: {
            HStack(spacing: Spacing.cardInset) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.brand)
                    .frame(width: 28)

                Text(title)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color.ink)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }

    private func openPendingOption() {
        switch pendingOption {
        case .scan: isShowingScanner = true
        case .search: isShowingSearch = true
        case .manual: isShowingAddManually = true
        case nil: break
        }
        pendingOption = nil
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
        .background(.surface)
    }

    private var libraryList: some View {
        List {
            ForEach(booksByStatus, id: \.status) { section in
                Section(section.status.displayName) {
                    ForEach(section.items) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            HStack(spacing: Spacing.md) {
                                LibraryCoverView(book: book)
                                
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(book.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.ink)
                                        .lineLimit(2)
                                    
                                    Text(book.author)
                                        .font(.bodySupporting)
                                        .foregroundStyle(.inkMuted)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.captionStrong)
                                    .foregroundStyle(Color.inkFaint)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.surface)
    }
    
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: Spacing.cardInset) {
                Spacer(minLength: 88)
                
                Image(systemName: "books.vertical")
                    .font(.iconSection)
                    .foregroundStyle(.brand)
                
                Text(Localization.Library.emptyTitle.string)
                    .font(.titleSecondary)
                
                Text(Localization.Library.emptySubtitle.string)
                    .font(.bodyDefault)
                    .foregroundStyle(.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.xl)
        }
    }
    
}

#Preview {
    NavigationStack {
        Library()
            .environment(LibraryStore())
    }
}
