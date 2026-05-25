import SwiftUI

struct Search: View {
    @State private var searchText = ""
    @State private var submittedQuery = ""
    @State private var results: [SearchBook] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isSearchFocused: Bool

    private let service = GoogleBooksService()

    private let genres: [GenreItem] = [
        .init(title: "Science Fiction", query: "science fiction books", icon: "sparkles"),
        .init(title: "Philosophy", query: "philosophy books", icon: "brain.head.profile"),
        .init(title: "History", query: "history books", icon: "building.columns"),
        .init(title: "Mystery", query: "mystery books", icon: "magnifyingglass"),
        .init(title: "Poetry", query: "poetry books", icon: "pencil.and.scribble"),
        .init(title: "Design", query: "design books", icon: "pencil.and.ruler"),
    ]

    private let discoverQueries: [String] = [
        "best seller books",
        "classic novels",
        "award winning books"
    ]

    var body: some View {
        VStack(spacing: 12) {
            searchField

            if submittedQuery.isEmpty {
                discoveryView
            } else {
                resultsView
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(.backgroundPrimary)
        .navigationTitle("Search")
        .task {
            await loadDiscoverBooksIfNeeded()
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(uiColor: .secondaryLabel))

            TextField("Search books, authors, or ISBN", text: $searchText)
                .foregroundStyle(Color(uiColor: .label))
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task { await runSearch() }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    submittedQuery = ""
                    results = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
            }

            Button {
                Task { await runSearch() }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.emphasis)
            }
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
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

    private var discoveryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Browse by Genre")
                    .font(.system(.title2, weight: .bold))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(genres) { genre in
                        Button {
                            searchText = genre.query
                            Task { await runSearch(with: genre.query) }
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

                                Text(genre.title)
                                    .font(.system(.title3, weight: .semibold))
                                    .foregroundStyle(Color(uiColor: .label))
                                    .padding(14)
                            }
                            .frame(height: 126)
                        }
                    }
                }

                HStack {
                    Text("Discover")
                        .font(.system(.title2, weight: .bold))

                    Spacer()

                    Button("See All") {
                        searchText = "best books"
                        Task { await runSearch(with: "best books") }
                    }
                    .foregroundStyle(.emphasis)
                }

                if discoverBooks.isEmpty {
                    ProgressView("Loading discovery...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(discoverBooks) { book in
                                NavigationLink(destination: SearchBookDetails(book: book, service: service)) {
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
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    @State private var discoverBooks: [SearchBook] = []

    private var resultsView: some View {
        Group {
            if isLoading {
                ProgressView("Searching books...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                ContentUnavailableView("Search failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else if results.isEmpty {
                ContentUnavailableView("No books found", systemImage: "book.closed", description: Text("Try another title."))
            } else {
                List(results) { book in
                    NavigationLink(destination: SearchBookDetails(book: book, service: service)) {
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
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.backgroundPrimary)
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    private func runSearch(with forcedQuery: String? = nil) async {
        let query = (forcedQuery ?? searchText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return }

        isSearchFocused = false
        submittedQuery = query
        isLoading = true
        errorMessage = nil

        do {
            results = try await service.searchBooks(query: query)
        } catch {
            if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
                errorMessage = description
            } else {
                errorMessage = "Please check your connection and try again."
            }
        }

        isLoading = false
    }

    private func loadDiscoverBooksIfNeeded() async {
        guard discoverBooks.isEmpty else { return }

        var merged: [SearchBook] = []
        var ids = Set<String>()

        for query in discoverQueries {
            do {
                let found = try await service.searchBooks(query: query)
                for book in found where !ids.contains(book.id) {
                    ids.insert(book.id)
                    merged.append(book)
                    if merged.count >= 12 {
                        discoverBooks = merged
                        return
                    }
                }
            } catch {
                continue
            }
        }

        discoverBooks = merged
    }
}

private struct GenreItem: Identifiable {
    let id = UUID()
    let title: String
    let query: String
    let icon: String
}

#Preview {
    Search()
}
