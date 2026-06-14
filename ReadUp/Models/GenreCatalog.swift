import Foundation

/// Um gênero literário do catálogo do app.
/// O `id`/`title` é o valor canônico salvo no backend (em `User.genres`).
/// `query` é usado pra buscar livros na Google Books API; `icon` é um SF Symbol.
struct Genre: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let query: String
    let icon: String
}

/// Catálogo único de gêneros, reutilizado pelo onboarding, Search e Profile.
enum GenreCatalog {
    static let all: [Genre] = [
        .init(title: "Fantasy",         query: "fantasy books",         icon: "wand.and.stars"),
        .init(title: "Science Fiction", query: "science fiction books", icon: "sparkles"),
        .init(title: "Romance",         query: "romance novels",        icon: "heart.fill"),
        .init(title: "Mystery",         query: "mystery books",         icon: "magnifyingglass"),
        .init(title: "Thriller",        query: "thriller books",        icon: "bolt.fill"),
        .init(title: "Horror",          query: "horror books",          icon: "theatermasks.fill"),
        .init(title: "History",         query: "history books",         icon: "building.columns.fill"),
        .init(title: "Philosophy",      query: "philosophy books",      icon: "brain.head.profile"),
        .init(title: "Poetry",          query: "poetry books",          icon: "pencil.and.scribble"),
        .init(title: "Biography",       query: "biography books",       icon: "person.fill"),
        .init(title: "Self-Help",       query: "self help books",       icon: "figure.mind.and.body"),
        .init(title: "Science",         query: "popular science books", icon: "atom"),
        .init(title: "Business",        query: "business books",        icon: "chart.line.uptrend.xyaxis"),
        .init(title: "Comics",          query: "comics graphic novels", icon: "books.vertical.fill"),
        .init(title: "Design",          query: "design books",          icon: "pencil.and.ruler.fill"),
    ]

    /// Busca um gênero pelo título (valor salvo no backend).
    static func genre(for title: String) -> Genre? {
        all.first { $0.title == title }
    }

    /// Resolve uma lista de títulos salvos para os gêneros do catálogo (ignora desconhecidos).
    static func genres(for titles: [String]) -> [Genre] {
        titles.compactMap { genre(for: $0) }
    }
}
