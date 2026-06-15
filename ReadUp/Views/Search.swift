import SwiftUI

struct Search: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SearchViewModel.self) private var viewModel
    @State private var selectedBook: SearchBook?
    @FocusState private var isSearchFocused: Bool

    private var chosenGenres: [Genre] {
        GenreCatalog.genres(for: authManager.genres)
    }

    var body: some View {
        VStack(spacing: 12) {
            searchField

            if viewModel.submittedQuery.isEmpty {
                recommendationsView
            } else {
                resultsView
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(.backgroundPrimary)
        .navigationTitle(Localization.Search.title.string)
        .sheet(item: $selectedBook) { book in
            BookDetailsSheet(source: .search(book, viewModel.service))
                .presentationDragIndicator(.visible)
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
                .foregroundStyle(Color(uiColor: .secondaryLabel))

            TextField(Localization.Search.placeholder.string, text: $bindableViewModel.searchText)
                .foregroundStyle(Color(uiColor: .label))
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
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
            }

            Button {
                isSearchFocused = false
                Task { await viewModel.runSearch() }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.emphasis)
            }
            .disabled(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSearchFocused ? Color.emphasis : Color(uiColor: .separator), lineWidth: isSearchFocused ? 1.4 : 1)
        )
    }

    // MARK: - Recomendações (uma seção por gênero escolhido)

    private var recommendationsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                if !chosenGenres.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(viewModel.genreSections) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(section.genre.localizedTitle)
                                        .font(.system(.title2, weight: .bold))
                                        
                                    Spacer()
                                    
                                    Button(Localization.Search.seeAll.string) {
                                        isSearchFocused = false
                                        viewModel.searchText = section.genre.localizedTitle
                                        Task { await viewModel.runSearch(with: section.genre.query) }
                                    }
                                    .foregroundStyle(.emphasis)
                                }

                                if section.books.isEmpty {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 120)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
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

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(Localization.Search.discover.string)
                            .font(.system(.title2, weight: .bold))

                        Spacer()

                        Button(Localization.Search.seeAll.string) {
                            isSearchFocused = false
                            viewModel.searchText = "best books"
                            Task { await viewModel.runSearch(with: "best books") }
                        }
                        .foregroundStyle(.emphasis)
                    }

                    if viewModel.discoverBooks.isEmpty {
                        ProgressView(Localization.Search.loadingDiscovery.string)
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.discoverBooks) { book in
                                    bookCard(book)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(Localization.Search.browseByGenre.string)
                        .font(.system(.title2, weight: .bold))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(GenreCatalog.all) { genre in
                            Button {
                                isSearchFocused = false
                                viewModel.searchText = genre.query
                                Task { await viewModel.runSearch(with: genre.query) }
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.emphasis.opacity(0.12))

                                    Image(systemName: genre.icon)
                                        .font(.system(size: 42, weight: .regular))
                                        .foregroundStyle(Color.emphasis.opacity(0.18))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        .padding(.top, 14)
                                        .padding(.trailing, 12)

                                    Text(genre.localizedTitle)
                                        .font(.system(.title3, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .padding(14)
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
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: book.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color(uiColor: .tertiarySystemFill)
                    }
                }
                .frame(width: 146, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(Color(uiColor: .label))

                Text(book.author)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(.secundaryLabel)
            }
            .frame(width: 146, alignment: .leading)
        }
        .buttonStyle(.plain)
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
                ContentUnavailableView(Localization.Search.noResults.string, systemImage: "book.closed", description: Text(Localization.Search.tryAnother.string))
            } else {
                List {
                    ForEach(viewModel.results) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            HStack(spacing: 12) {
                                AsyncImage(url: book.thumbnailURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    default:
                                        Color(uiColor: .tertiarySystemFill)
                                    }
                                }
                                .frame(width: 50, height: 74)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title)
                                        .font(.system(.headline, weight: .semibold))
                                        .lineLimit(2)

                                    Text(book.author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secundaryLabel)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    }
                    
                    if viewModel.hasMoreResults {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 8)
                        .onAppear {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    } else if !viewModel.results.isEmpty {
                        Text(Localization.Search.noMoreResults.string)
                            .font(.footnote)
                            .foregroundStyle(.secundaryLabel)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.backgroundPrimary)
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
