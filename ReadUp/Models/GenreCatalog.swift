import Foundation

/// Um gênero literário do catálogo do app.
/// O `id`/`title` é o valor canônico salvo no backend (em `User.genres`).
/// `query` é usado pra buscar livros na Google Books API; `icon` é um SF Symbol.
struct Genre: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let query: String
    let icon: String

    var localizedTitle: String {
        switch title {
        case "Fantasy": return Localization.Genre.fantasy.string
        case "Science Fiction": return Localization.Genre.scienceFiction.string
        case "Romance": return Localization.Genre.romance.string
        case "Mystery": return Localization.Genre.mystery.string
        case "Thriller": return Localization.Genre.thriller.string
        case "Horror": return Localization.Genre.horror.string
        case "History": return Localization.Genre.history.string
        case "Philosophy": return Localization.Genre.philosophy.string
        case "Poetry": return Localization.Genre.poetry.string
        case "Biography": return Localization.Genre.biography.string
        case "Self-Help": return Localization.Genre.selfHelp.string
        case "Science": return Localization.Genre.science.string
        case "Business": return Localization.Genre.business.string
        case "Comics": return Localization.Genre.comics.string
        case "Design": return Localization.Genre.design.string
        default: return title
        }
    }
}

/// Catálogo único de gêneros, reutilizado pelo onboarding, Search e Profile.
enum GenreCatalog {
    // `query` usa o qualificador `subject:` da Google Books API, bem mais preciso que
    // texto livre. O ranking de recência do backend traz os títulos mais contemporâneos.
    static let all: [Genre] = [
        .init(title: "Fantasy",         query: "subject:fantasy",         icon: "wand.and.stars"),
        .init(title: "Science Fiction", query: "subject:science fiction", icon: "sparkles"),
        .init(title: "Romance",         query: "subject:romance",         icon: "heart.fill"),
        .init(title: "Mystery",         query: "subject:mystery",         icon: "magnifyingglass"),
        .init(title: "Thriller",        query: "subject:thriller",        icon: "bolt.fill"),
        .init(title: "Horror",          query: "subject:horror",          icon: "theatermasks.fill"),
        .init(title: "History",         query: "subject:history",         icon: "building.columns.fill"),
        .init(title: "Philosophy",      query: "subject:philosophy",      icon: "brain.head.profile"),
        .init(title: "Poetry",          query: "subject:poetry",          icon: "pencil.and.scribble"),
        .init(title: "Biography",       query: "subject:biography",       icon: "person.fill"),
        .init(title: "Self-Help",       query: "subject:self-help",       icon: "figure.mind.and.body"),
        .init(title: "Science",         query: "subject:science",         icon: "atom"),
        .init(title: "Business",        query: "subject:business",        icon: "chart.line.uptrend.xyaxis"),
        .init(title: "Comics",          query: "subject:comics",          icon: "books.vertical.fill"),
        .init(title: "Design",          query: "subject:design",          icon: "pencil.and.ruler.fill"),
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
