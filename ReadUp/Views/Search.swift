import SwiftUI

/// A busca de livros. Figma `47:1664` (resultados) e `47:1714` (nada encontrado).
///
/// Não é uma aba: chega-se aqui pelo `+` da Library. O topo é a pílula de busca com o
/// chip de voltar; o rodapé carrega sempre a saída para o cadastro manual, porque o
/// catálogo erra e a alternativa tem que estar à vista.
struct Search: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// "Add another book" depois de cair no cadastro manual: por padrão fecha só esta
    /// tela. Quem abre a busca aninhada sob outra folha (a 08b do scanner) passa aqui o
    /// fechamento dessa folha também, pra cascatear até a tela de origem. Não se aplica
    /// à conquista do `+` direto num resultado — essa fica na própria busca de propósito.
    var onAddAnother: () -> Void = {}

    @State private var selectedBook: SearchBook?
    @State private var isShowingAddManually = false
    @State private var addedBook: Book?
    @State private var addingBookID: String?
    @State private var showAuth = false
    @FocusState private var isSearchFocused: Bool
    // Mesma camada da frente da Library: a capa tocada é promovida e não sai de tela.
    @State private var frameStore = CoverFrameStore()
    @State private var flyingBook: SearchBook?
    @State private var heroPlacement = HeroPlacement()
    @State private var isFlying = false

    private var chosenGenres: [Genre] {
        GenreCatalog.genres(for: authManager.genres)
    }

    private var isShowingResults: Bool { !viewModel.submittedQuery.isEmpty }

    var body: some View {
        // Mesma troca da Library: a camada de baixo muda, a capa tocada voa por cima.
        ZStack {
            Group {
                if let book = selectedBook {
                    BookDetailsView(
                        source: .search(book, viewModel.service),
                        onHeroPlacement: place,
                        onClose: { select(nil) }
                    )
                    .transition(.opacity)
                } else {
                    searchScreen
                        .transition(.opacity)
                }
            }

            if let flyingBook, heroPlacement.isPlaced {
                FlyingCover(
                    coverUrl: flyingBook.thumbnailURL?.absoluteString,
                    title: flyingBook.title,
                    author: flyingBook.author,
                    placement: heroPlacement
                )
            }
        }
        .coordinateSpace(.named(HeroSpace.name))
        .background(Palette.surface)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingAddManually) {
            BookFormView(mode: .create, onAddAnother: { dismiss(); onAddAnother() })
        }
        .fullScreenCover(item: $addedBook) { book in
            BookAddedView(book: book) { dismiss() }
        }
        .sheet(isPresented: $showAuth) { AuthSheet() }
        .task { await reloadRecommendations() }
        .onChange(of: authManager.genres) {
            Task { await reloadRecommendations() }
        }
    }

    /// Abre ou fecha o detalhe, promovendo a capa tocada à camada da frente.
    private func select(_ book: SearchBook?) {
        if let book {
            flyingBook = book
            // Sem frame de origem (capa nunca medida) não há de onde voar: a capa
            // aparece já no lugar quando o detalhe disser onde é. Nunca fica sem capa.
            if let origin = frameStore.frame(for: book.id) {
                heroPlacement = HeroPlacement(frame: origin)
                isFlying = true
            } else {
                heroPlacement = HeroPlacement()
                isFlying = false
            }
            withAnimation(Motion.heroFlight) { selectedBook = book }
        } else {
            isFlying = true
            let origin = flyingBook.flatMap { frameStore.frame(for: $0.id) }
            withAnimation(Motion.heroFlight) {
                selectedBook = nil
                if let origin { heroPlacement = HeroPlacement(frame: origin) }
            } completion: {
                flyingBook = nil
                isFlying = false
            }
        }
    }

    private func place(_ placement: HeroPlacement) {
        guard isFlying else {
            heroPlacement = placement
            return
        }
        withAnimation(Motion.heroFlight) {
            heroPlacement = placement
        } completion: {
            isFlying = false
        }
    }

    private var searchScreen: some View {
        VStack(spacing: Spacing.lg) {
            searchBar

            if isShowingResults {
                resultsView
            } else {
                recommendationsView
            }
        }
        .padding(.horizontal, Spacing.gutterList)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.surface)
        .safeAreaInset(edge: .bottom) { bottomInset }
    }

    private func reloadRecommendations() async {
        async let discover: () = viewModel.loadDiscoverBooksIfNeeded()
        async let sections: () = viewModel.loadSections(for: chosenGenres)
        _ = await (discover, sections)
    }

    private func submit(_ query: String? = nil) {
        isSearchFocused = false
        Task { await viewModel.runSearch(with: query) }
    }

    // MARK: - Topo

    /// Chip de voltar + pílula de busca. Figma `47:1668`.
    private var searchBar: some View {
        @Bindable var bindableViewModel = viewModel

        return HStack(spacing: Spacing.md) {
            ChromeChip(systemImage: "chevron.left") { dismiss() }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.iconLabel)
                    .foregroundStyle(Palette.inkFaint)

                TextField(
                    "",
                    text: $bindableViewModel.searchText,
                    prompt: Text(Localization.Search.placeholder.string)
                        .foregroundStyle(Palette.inkFaint)
                )
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.ink)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit { submit() }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.captionDefault)
                            .foregroundStyle(Palette.inkFainter)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Capsule(style: .continuous).fill(Palette.surfaceRaised))
        }
    }

    // MARK: - Rodapé

    /// Resultados: o cartão "não é esta edição?". Nada encontrado: a ação primária.
    /// Recomendações: nada — o rodapé só existe depois de uma busca.
    @ViewBuilder
    private var bottomInset: some View {
        if isShowingResults && !viewModel.isLoading {
            Group {
                if viewModel.results.isEmpty {
                    ReadUpButton(title: Localization.Search.addThisBookManually.string) {
                        isSearchFocused = false
                        isShowingAddManually = true
                    }
                } else {
                    catalogBanner
                }
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.top, Spacing.md)
            .padding(.bottom, 30)
            .background(Palette.surface)
        }
    }

    /// Figma `47:1711`.
    private var catalogBanner: some View {
        Button {
            isSearchFocused = false
            isShowingAddManually = true
        } label: {
            HStack(spacing: Spacing.md) {
                Text(Localization.Search.catalogCaveat.string)
                    .textStyle(.captionDefault)
                    .foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(Localization.Search.addManually.string)
                    .textStyle(.label)
                    .foregroundStyle(Palette.ink)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.cardInset)
            .cardSurface()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Resultados

    @ViewBuilder
    private var resultsView: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(Palette.inkMuted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            emptyResults(
                title: Localization.Search.failed.string,
                subtitle: errorMessage
            )
        } else if viewModel.results.isEmpty {
            emptyResults(
                title: Localization.Search.noMatchTitle.string,
                subtitle: Localization.Search.noMatchSubtitle.string
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.results) { book in
                        resultRow(book)
                    }

                    if viewModel.hasMoreResults {
                        ProgressView()
                            .tint(Palette.inkMuted)
                            .padding(.vertical, Spacing.lg)
                            .onAppear { Task { await viewModel.loadMore() } }
                    }
                }
            }
            .scrollIndicators(.never)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    /// Uma linha de resultado. Figma `47:1676`.
    private func resultRow(_ book: SearchBook) -> some View {
        HStack(spacing: Spacing.cardInset) {
            Button {
                select(book)
            } label: {
                HStack(spacing: Spacing.cardInset) {
                    resultCover(book)
                        .opacity(flyingBook?.id == book.id ? 0 : 1)
                        .recordsCoverFrame(frameStore, id: book.id)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.title)
                            .textStyle(.headingRow)
                            .foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.leading)

                        Text(metaLine(for: book))
                            .textStyle(.captionDefault)
                            .foregroundStyle(Palette.inkMeta)
                            .multilineTextAlignment(.leading)

                        // A contagem de páginas é o que alimenta progresso e sessões:
                        // sem ela o livro entra incompleto, e isso é dito na linha.
                        if book.numberOfPages <= 0 {
                            Text(Localization.Search.pageCountMissing.string)
                                .textStyle(.captionFine)
                                .foregroundStyle(Palette.warning)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            addButton(book)
        }
        .padding(.vertical, Spacing.md)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.divider).frame(height: 1)
        }
    }

    @ViewBuilder
    private func resultCover(_ book: SearchBook) -> some View {
        if book.thumbnailURL == nil {
            // Sem capa é dito com todas as letras — o placeholder tipográfico ficaria
            // ilegível a 46pt e é reservado à capa herói.
            Text(Localization.Search.noCover.string)
                .textStyle(.captionFine)
                .foregroundStyle(Palette.inkFaint)
                .multilineTextAlignment(.center)
                .frame(width: 46, height: 66)
                .background(
                    RoundedRectangle(cornerRadius: Radius.coverSm, style: .continuous)
                        .fill(Palette.surfaceSunken)
                )
        } else {
            BookCoverView(
                coverUrl: book.thumbnailURL?.absoluteString,
                width: 46,
                height: 66,
                cornerRadius: Radius.coverSm
            )
        }
    }

    /// O `+` adiciona direto, com o status padrão — quem quiser escolher abre o detalhe.
    private func addButton(_ book: SearchBook) -> some View {
        Button {
            guard !store.contains(book) else { return }
            guard !authManager.isGuest else { showAuth = true; return }
            addingBookID = book.id
            Task {
                addedBook = await store.addBook(from: book, status: .iWantToRead)
                addingBookID = nil
            }
        } label: {
            Group {
                if addingBookID == book.id {
                    ProgressView().tint(Palette.onBrand)
                } else {
                    Image(systemName: store.contains(book) ? "checkmark" : "plus")
                        .font(.iconLabel)
                        .foregroundStyle(Palette.onBrand)
                }
            }
            .frame(width: 30, height: 30)
            .background(Circle().fill(Palette.brand))
            .opacity(store.contains(book) ? Motion.disabledOpacity : 1)
        }
        .buttonStyle(.plain)
        .disabled(store.contains(book) || addingBookID != nil)
        .accessibilityLabel(Localization.BookDetails.addToLibrary.string)
    }

    /// "Autor · 443 p." — o catálogo não devolve ano, então a linha não o inventa.
    private func metaLine(for book: SearchBook) -> String {
        var parts = [book.author]
        if book.numberOfPages > 0 {
            parts.append(Localization.Search.pageCount(book.numberOfPages))
        }
        return parts.joined(separator: " · ")
    }

    /// Nada encontrado. Figma `47:1714`.
    private func emptyResults(title: String, subtitle: String) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: Radius.cover, style: .continuous)
                .strokeBorder(
                    Palette.borderStrong,
                    style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                )
                .frame(width: 104, height: 138)
                .overlay(
                    Text(verbatim: "?")
                        .textStyle(.titleSecondary)
                        .foregroundStyle(Palette.inkFainter)
                )
                .padding(.bottom, Spacing.xl)

            Text(title)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .padding(.bottom, Spacing.sm)

            Text(subtitle)
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, Spacing.xxl)
    }

    // MARK: - Recomendações

    private var recommendationsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ForEach(viewModel.genreSections) { section in
                    shelf(title: section.genre.localizedTitle, books: section.books) {
                        viewModel.searchText = section.genre.localizedTitle
                        submit(section.genre.query)
                    }
                }

                shelf(title: Localization.Search.discover.string, books: viewModel.discoverBooks) {
                    viewModel.searchText = "best books"
                    submit("best books")
                }

                genreGrid
            }
            .padding(.bottom, Spacing.xxl)
        }
        .scrollIndicators(.never)
        .scrollDismissesKeyboard(.immediately)
    }

    private func shelf(title: String, books: [SearchBook], seeAll: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .textStyle(.titleTertiary)
                    .foregroundStyle(Palette.ink)

                Spacer()

                Button(Localization.Search.seeAll.string, action: seeAll)
                    .textStyle(.label)
                    .foregroundStyle(Palette.inkMuted)
            }
            .padding(.bottom, Spacing.sm)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Palette.divider).frame(height: 1)
            }

            if books.isEmpty {
                ProgressView()
                    .tint(Palette.inkMuted)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        ForEach(books) { book in
                            bookCard(book)
                        }
                    }
                    // A sombra das capas é cortada pelo ScrollView sem esta folga.
                    .padding(.vertical, Spacing.sm)
                }
                .scrollIndicators(.never)
            }
        }
    }

    private func bookCard(_ book: SearchBook) -> some View {
        Button {
            select(book)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                BookCoverView(
                    coverUrl: book.thumbnailURL?.absoluteString,
                    width: Spacing.coverShelfWidth,
                    height: Spacing.coverShelfHeight,
                    cornerRadius: Radius.cover,
                    title: book.title,
                    author: book.author
                )
                .coverShadow(.coverSm)
                .opacity(flyingBook?.id == book.id ? 0 : 1)
                .recordsCoverFrame(frameStore, id: book.id)

                Text(book.title)
                    .textStyle(.captionDefault)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: Spacing.coverShelfWidth, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var genreGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(Localization.Search.browseByGenre.string)
                .textStyle(.titleTertiary)
                .foregroundStyle(Palette.ink)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(GenreCatalog.all) { genre in
                    Button {
                        viewModel.searchText = genre.query
                        submit(genre.query)
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            Image(systemName: genre.icon)
                                .font(.iconSection)
                                .foregroundStyle(Palette.inkFainter)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                .padding(.top, Spacing.cardInset)
                                .padding(.trailing, Spacing.md)

                            Text(genre.localizedTitle)
                                .textStyle(.titleTertiary)
                                .foregroundStyle(Palette.ink)
                                .multilineTextAlignment(.leading)
                                .padding(Spacing.cardInset)
                        }
                        .frame(height: 126)
                        .fillSurface(radius: Radius.card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    Search()
        .environment(AuthManager())
        .environment(SearchViewModel())
        .environment(LibraryStore())
}
