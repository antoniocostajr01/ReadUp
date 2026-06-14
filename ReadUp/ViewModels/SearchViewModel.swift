import Foundation
import SwiftUI

/// Uma seção da tela de Search: um gênero escolhido + os livros encontrados.
struct GenreSection: Identifiable {
    var id: String { genre.id }
    let genre: Genre
    let books: [SearchBook]
}

@Observable
final class SearchViewModel {
    var searchText = ""
    var submittedQuery = ""
    var results: [SearchBook] = []
    var isLoading = false
    var isFetchingMore = false
    var hasMoreResults = true
    var currentStartIndex = 0
    let pageSize = 40
    var errorMessage: String?

    // Recomendações por gênero (estado padrão, sem busca digitada).
    var genreSections: [GenreSection] = []
    var isLoadingSections = false

    // Fallback quando o usuário não tem gêneros escolhidos.
    var discoverBooks: [SearchBook] = []

    let service: GoogleBooksService

    /// Cache por título de gênero pra não rebuscar o que já foi carregado.
    private var cache: [String: [SearchBook]] = [:]

    init(service: GoogleBooksService = GoogleBooksService()) {
        self.service = service
    }

    private let discoverQueries: [String] = [
        "best seller books",
        "classic novels",
        "award winning books"
    ]

    // MARK: - Busca manual

    @MainActor
    func runSearch(with forcedQuery: String? = nil) async {
        let query = (forcedQuery ?? searchText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return }

        submittedQuery = query
        isLoading = true
        errorMessage = nil
        hasMoreResults = true
        currentStartIndex = 0

        do {
            results = try await service.searchBooks(query: query, maxResults: pageSize, startIndex: currentStartIndex)
            if results.count < pageSize {
                hasMoreResults = false
            }
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
    func loadMore() async {
        guard !isFetchingMore, hasMoreResults, !submittedQuery.isEmpty else { return }
        
        isFetchingMore = true
        currentStartIndex += pageSize
        
        do {
            let newBooks = try await service.searchBooks(query: submittedQuery, maxResults: pageSize, startIndex: currentStartIndex)
            
            let existingIds = Set(results.map { $0.id })
            let filteredNewBooks = newBooks.filter { !existingIds.contains($0.id) }
            
            results.append(contentsOf: filteredNewBooks)
            
            if newBooks.count < pageSize {
                hasMoreResults = false
            }
        } catch {
            hasMoreResults = false
        }
        
        isFetchingMore = false
    }

    // MARK: - Recomendações por gênero

    /// Monta uma seção por gênero escolhido. Reusa o cache; busca só os novos.
    /// Ao remover um gênero, ele some naturalmente (não está mais em `genres`).
    @MainActor
    func loadSections(for genres: [Genre]) async {
        guard !genres.isEmpty else {
            genreSections = []
            return
        }

        isLoadingSections = genreSections.isEmpty
        var result: [GenreSection] = []

        for genre in genres {
            if let cached = cache[genre.title] {
                result.append(GenreSection(genre: genre, books: cached))
                genreSections = result
                continue
            }
            do {
                let books = try await service.searchBooks(query: genre.query)
                cache[genre.title] = books
                result.append(GenreSection(genre: genre, books: books))
            } catch {
                result.append(GenreSection(genre: genre, books: []))
            }
            genreSections = result
        }

        genreSections = result
        isLoadingSections = false
    }

    // MARK: - Fallback (sem gêneros)

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
        hasMoreResults = true
        currentStartIndex = 0
        isFetchingMore = false
    }
}
