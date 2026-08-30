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
        // Ordem do Figma, não a do enum: Lendo primeiro, abandonados por último.
        let shelfOrder: [BookStatus] = [.reading, .iWantToRead, .read, .rereading, .abandoned]
        let orderedStatuses = shelfOrder.filter { status in
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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                searchField

                if books.isEmpty {
                    emptyState
                } else if booksByStatus.isEmpty {
                    noResultsState
                } else {
                    ForEach(booksByStatus, id: \.status) { shelf in
                        shelfView(shelf.status, books: shelf.items)
                    }
                }
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.top, Spacing.cardInset)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Palette.surface)
        .toolbar(.hidden, for: .navigationBar)
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
    }

    // MARK: - Cabeçalho e busca

    /// Título e o "+" em ink. Figma `41:1019`.
    private var header: some View {
        HStack {
            Text(Localization.Library.title.string)
                .textStyle(.titleScreenLarge)
                .foregroundStyle(Palette.ink)

            Spacer()

            Button {
                isShowingAddOptions = true
            } label: {
                Image(systemName: "plus")
                    .font(.iconLabel)
                    .foregroundStyle(Palette.onBrand)
                    .frame(width: Spacing.addCircle, height: Spacing.addCircle)
                    .background(Circle().fill(Palette.brand))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.BookDetails.addToLibrary.string)
            // O modal cresce a partir do próprio "+", em vez de subir do rodapé.
            .matchedTransitionSource(id: "addBook", in: addButtonNamespace)
        }
    }

    /// Pílula de busca do design, no lugar do `.searchable` do sistema. Figma `41:1023`.
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.iconLabel)
                .foregroundStyle(Palette.inkFaint)

            TextField(
                "",
                text: $searchText,
                prompt: Text(Localization.Library.searchPrompt.string)
                    .foregroundColor(Palette.inkFaint)
            )
            .textStyle(.bodySupporting)
            .foregroundStyle(Palette.ink)
            .submitLabel(.search)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(Capsule().fill(Palette.surfaceRaised))
    }

    // MARK: - Prateleiras

    /// Uma prateleira: cabeça com nome, contagem e chevron, e as capas em linha.
    /// Figma `41:1026`.
    private func shelfView(_ status: BookStatus, books shelfBooks: [Book]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(status.displayName)
                    .textStyle(.titleTertiary)
                    .foregroundStyle(Palette.ink)

                Text(Localization.Library.bookCount(shelfBooks.count))
                    .textStyle(.captionFine)
                    .foregroundStyle(Palette.inkFaint)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.iconLabel)
                    .foregroundStyle(Palette.inkMeta)
            }
            .padding(.bottom, Spacing.sm)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Palette.divider).frame(height: 1)
            }

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    ForEach(shelfBooks) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            ShelfCover(
                                book: book,
                                progress: status == .reading ? progressValue(for: book) : nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                // A sombra das capas é cortada pelo ScrollView sem esta folga.
                .padding(.vertical, Spacing.sm)
            }
            .scrollIndicators(.never)
        }
    }

    private func progressValue(for book: Book) -> Double {
        guard book.numberOfPages > 0 else { return 0 }
        return min(1, max(0, Double(book.progress ?? 0) / Double(book.numberOfPages)))
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

    private var noResultsState: some View {
        VStack(spacing: Spacing.cardInset) {
            Text(Localization.Library.noResultsTitle.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)

            Text(Localization.Library.noResultsSubtitle.string)
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.cardInset) {
            Image(systemName: "books.vertical")
                .font(.iconSection)
                .foregroundStyle(Palette.inkFainter)

            Text(Localization.Library.emptyTitle.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)

            Text(Localization.Library.emptySubtitle.string)
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
    
}

#Preview {
    NavigationStack {
        Library()
            .environment(LibraryStore())
    }
}
