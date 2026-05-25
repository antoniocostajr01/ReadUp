import SwiftData
import SwiftUI

struct Search: View {
    @State private var searchText = ""
    @State private var results: [SearchBook] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    private let service = GoogleBooksService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                searchField

                Group {
                    if isLoading {
                        ProgressView("Searching books...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage {
                        ContentUnavailableView("Search failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                    } else if searchText.isEmpty {
                        ContentUnavailableView("Find any book", systemImage: "magnifyingglass", description: Text("Type a title and we'll find matching books."))
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
                                            .foregroundStyle(Color(uiColor: .label))
                                            .lineLimit(2)

                                        Text(book.author)
                                            .font(.subheadline)
                                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color(uiColor: .secondarySystemBackground))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color(uiColor: .systemBackground))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Search")
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

                if trimmedValue.count < 2 {
                    results = []
                    errorMessage = nil
                    isLoading = false
                    return
                }

                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    await searchBooks()
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(uiColor: .secondaryLabel))

            TextField("Search by book title", text: $searchText)
                .foregroundStyle(Color(uiColor: .label))
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSearchFocused ? Color.emphasis : Color(uiColor: .separator), lineWidth: isSearchFocused ? 1.5 : 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func searchBooks() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await service.searchBooks(query: searchText)
        } catch {
            errorMessage = "Please check your connection and try again."
        }
        isLoading = false
    }
}

#Preview {
    Search()
}
