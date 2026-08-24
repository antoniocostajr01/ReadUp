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
        .background(.backgroundPrimary)
    }

    // MARK: - Modal de adicionar livro

    private var addOptionsSheet: some View {
        VStack(spacing: 12) {
            Text(Localization.BookDetails.addToLibrary.string)
                .font(.system(.title2, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            addOptionRow(Localization.Library.scan.string, icon: "barcode.viewfinder", option: .scan)
            addOptionRow(Localization.Library.searchOption.string, icon: "magnifyingglass", option: .search)
            addOptionRow(Localization.Library.addManually.string, icon: "square.and.pencil", option: .manual)

            Spacer()
        }
        .padding(24)
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
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.emphasis)
                    .frame(width: 28)

                Text(title)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .label))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
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
            .environment(LibraryStore())
    }
}
