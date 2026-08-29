import SwiftUI

struct Search: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SearchViewModel.self) private var viewModel
    @State private var selectedBook: SearchBook?
    @State private var isShowingAddManually = false
    @FocusState private var isSearchFocused: Bool

    private var chosenGenres: [Genre] {
        GenreCatalog.genres(for: authManager.genres)
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            searchField

            if viewModel.submittedQuery.isEmpty {
                recommendationsView
            } else {
                resultsView
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .background(.surface)
        .navigationTitle(Localization.Search.title.string)
        .sheet(item: $selectedBook) { book in
            BookDetailsSheet(source: .search(book, viewModel.service))
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAddManually) {
            BookFormView(mode: .create)
        }
        .task {
            await reloadRecommendations()
        }
        .onChange(of: authManager.genres) {
            Task { await reloadRecommendations() }
        }
    }

    private func reloadRecommendations() async {
        async let discover: () = viewModel.loadDiscoverBooksIfNeeded()
        async let sections: () = viewModel.loadSections(for: chosenGenres)
        _ = await (discover, sections)
    }

    private var searchField: some View {
        @Bindable var bindableViewModel = viewModel
        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.inkMuted)

            TextField(Localization.Search.placeholder.string, text: $bindableViewModel.searchText)
                .foregroundStyle(Color.ink)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    isSearchFocused = false
                    Task { await viewModel.runSearch() }
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.inkFaint)
                }
            }

            Button {
                isSearchFocused = false
                Task { await viewModel.runSearch() }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.brand)
            }
            .disabled(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
        }
        .padding(.horizontal, Spacing.cardInset)
        .padding(.vertical, Spacing.md)
        .cardSurface(radius: Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(isSearchFocused ? Color.brand : Color.divider, lineWidth: isSearchFocused ? 1.4 : 1)
        )
    }

    // MARK: - Recomendações (uma seção por gênero escolhido)

    private var recommendationsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                
                if !chosenGenres.isEmpty {
                    LazyVStack(alignment: .leading, spacing: Spacing.xl) {
                        ForEach(viewModel.genreSections) { section in
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack {
                                    Text(section.genre.localizedTitle)
                                        .font(.titleSecondary)
                                        
                                    Spacer()
                                    
                                    Button(Localization.Search.seeAll.string) {
                                        isSearchFocused = false
                                        viewModel.searchText = section.genre.localizedTitle
                                        Task { await viewModel.runSearch(with: section.genre.query) }
                                    }
                                    .foregroundStyle(.brand)
                                }

                                if section.books.isEmpty {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 120)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: Spacing.md) {
                                            ForEach(section.books) { book in
                                                bookCard(book)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text(Localization.Search.discover.string)
                            .font(.titleSecondary)

                        Spacer()

                        Button(Localization.Search.seeAll.string) {
                            isSearchFocused = false
                            viewModel.searchText = "best books"
                            Task { await viewModel.runSearch(with: "best books") }
                        }
                        .foregroundStyle(.brand)
                    }

                    if viewModel.discoverBooks.isEmpty {
                        ProgressView(Localization.Search.loadingDiscovery.string)
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.md) {
                                ForEach(viewModel.discoverBooks) { book in
                                    bookCard(book)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(Localization.Search.browseByGenre.string)
                        .font(.titleSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                        ForEach(GenreCatalog.all) { genre in
                            Button {
                                isSearchFocused = false
                                viewModel.searchText = genre.query
                                Task { await viewModel.runSearch(with: genre.query) }
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                                        .fill(Color.brand.opacity(0.12))

                                    Image(systemName: genre.icon)
                                        .font(.system(size: 42, weight: .regular))
                                        .foregroundStyle(Color.brand.opacity(0.18))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        .padding(.top, Spacing.cardInset)
                                        .padding(.trailing, Spacing.md)

                                    Text(genre.localizedTitle)
                                        .font(.titleTertiary)
                                        .foregroundStyle(Color.ink)
                                        .padding(Spacing.cardInset)
                                }
                                .frame(height: 126)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func bookCard(_ book: SearchBook) -> some View {
        Button {
            selectedBook = book
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AsyncImage(url: book.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color.surfaceFill
                    }
                }
                .frame(width: 146, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(Color.ink)

                Text(book.author)
                    .font(.bodySupporting)
                    .lineLimit(1)
                    .foregroundStyle(.inkMuted)
            }
            .frame(width: 146, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    /// Estado "não achou o livro": ícone, título e atalho para o cadastro manual.
    private func notFoundState(title: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.iconEmptyState)
                .foregroundStyle(.inkMuted)
                .padding(.bottom, Spacing.sm)

            Text(title)
                .font(.system(.subheadline, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ink)
                .padding(.bottom, Spacing.lg)

            Text(Localization.Search.manualEntryHint.string)
                .font(.system(.subheadline, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ink)

            Text(Localization.Search.manualEntryDescription.string)
                .font(.bodySupporting)
                .multilineTextAlignment(.center)
                .foregroundStyle(.inkMuted)
                .padding(.bottom, Spacing.xl)

            Button {
                isSearchFocused = false
                isShowingAddManually = true
            } label: {
                HStack(spacing: Spacing.md) {
                    Text(Localization.Search.addManually.string)
                    Image(systemName: "square.and.pencil")
                }
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: 307, minHeight: 61)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(Color.brand))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 307)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Resultados da busca manual

    private var resultsView: some View {
        Group {
            if viewModel.isLoading {
                ProgressView(Localization.Search.searching.string)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(Localization.Search.failed.string, systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else if viewModel.results.isEmpty {
                notFoundState(title: Localization.Search.noResults.string)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.results) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            HStack(spacing: Spacing.md) {
                                AsyncImage(url: book.thumbnailURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    default:
                                        Color.surfaceFill
                                    }
                                }
                                .frame(width: 50, height: 74)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(book.title)
                                        .font(.headingRow)
                                        .lineLimit(2)

                                    Text(book.author)
                                        .font(.bodySupporting)
                                        .foregroundStyle(.inkMuted)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                    
                    if viewModel.hasMoreResults {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .padding(.vertical, Spacing.sm)
                        .onAppear {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    } else if !viewModel.results.isEmpty {
                        notFoundState(title: Localization.Search.noMoreResults.string)
                            .padding(.vertical, Spacing.xl)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.surface)
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }
}

#Preview {
    NavigationStack {
        Search()
            .environment(AuthManager())
            .environment(SearchViewModel())
    }
}
