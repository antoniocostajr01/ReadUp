import SwiftUI

struct Search: View {
    @State private var viewModel = SearchViewModel()
    @State private var selectedBook: SearchBook?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            searchField

            if viewModel.submittedQuery.isEmpty {
                discoveryView
            } else {
                resultsView
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(.backgroundPrimary)
        .navigationTitle("Search")
        .sheet(item: $selectedBook) { book in
            BookDetailsSheet(source: .search(book, viewModel.service))
                .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.loadDiscoverBooksIfNeeded()
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(uiColor: .secondaryLabel))

            TextField("Search books, authors, or ISBN", text: $viewModel.searchText)
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

    private var discoveryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Browse by Genre")
                    .font(.system(.title2, weight: .bold))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.genres) { genre in
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
                        isSearchFocused = false
                        viewModel.searchText = "best books"
                        Task { await viewModel.runSearch(with: "best books") }
                    }
                    .foregroundStyle(.emphasis)
                }

                if viewModel.discoverBooks.isEmpty {
                    ProgressView("Loading discovery...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.discoverBooks) { book in
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
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var resultsView: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Searching books...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView("Search failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else if viewModel.results.isEmpty {
                ContentUnavailableView("No books found", systemImage: "book.closed", description: Text("Try another title."))
            } else {
                List(viewModel.results) { book in
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.backgroundPrimary)
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }
}



#Preview {
    Search()
}
