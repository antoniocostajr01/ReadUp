import Foundation
import SwiftUI

@Observable
final class SearchViewModel {
    var searchText = ""
    var submittedQuery = ""
    var results: [SearchBook] = []
    var isLoading = false
    var errorMessage: String?
    var discoverBooks: [SearchBook] = []
    
    let service: GoogleBooksService
    
    init(service: GoogleBooksService = GoogleBooksService()) {
        self.service = service
    }
    
    let genres: [GenreItem] = [
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
    
    @MainActor
    func runSearch(with forcedQuery: String? = nil) async {
        let query = (forcedQuery ?? searchText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return }

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
    
    @MainActor
    func loadDiscoverBooksIfNeeded() async {
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
    
    func clearSearch() {
        searchText = ""
        submittedQuery = ""
        results = []
        errorMessage = nil
    }
}

struct GenreItem: Identifiable {
    let id = UUID()
    let title: String
    let query: String
    let icon: String
}
