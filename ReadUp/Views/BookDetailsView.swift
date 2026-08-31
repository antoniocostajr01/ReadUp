import SwiftUI

/// O detalhe do livro. Figma `47:1813` (na biblioteca) e `47:1849` (antes de adicionar).
///
/// Uma tela, duas origens: o layout é o mesmo, só o terço de baixo muda — quem já está
/// na biblioteca vê o status atual e "Continue reading"; quem veio da busca escolhe um
/// status e vê "Add to Library".
///
/// **Não é um modal.** É a tela inteira, trocada na camada de baixo de um `ZStack` por
/// quem a apresenta (`Library`, `Search`). A capa vive na camada da frente e voa da
/// prateleira até aqui por `matchedGeometryEffect` — é a única coisa que se move, todo o
/// resto faz cross-fade. Anotação do Figma `47:1906`.
struct BookDetailsView: View {
    enum Source {
        case library(Book)
        case search(SearchBook, GoogleBooksService)
    }

    @Environment(LibraryStore.self) private var store
    @Environment(AuthManager.self) private var authManager

    let source: Source
    /// O namespace da capa que voou até aqui, e o id dela.
    var heroNamespace: Namespace.ID? = nil
    /// Voltar: quem apresenta é que desfaz a troca, com animação.
    let onClose: () -> Void

    @State private var viewModel = BookDetailsViewModel()
    @State private var showAuth = false
    @State private var isShowingEditForm = false
    @State private var addedBook: Book?
    @State private var activeReadingBook: Book?
    /// Quanto o conteúdo já rolou. Encolhe e apaga a capa herói conforme sobe.
    @State private var scrollOffset: CGFloat = 0

    /// Capa herói: 224×320 no Figma `47:1822`.
    private let coverWidth: CGFloat = 224
    private let coverHeight: CGFloat = 320
    /// A capa desaparece por completo depois deste tanto de rolagem.
    private let collapseDistance: CGFloat = 220

    var body: some View {
        VStack(spacing: 0) {
            nav

            ScrollView {
                VStack(spacing: 18) {
                    cover
                    titles
                    stats
                    description
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .scrollIndicators(.never)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                scrollOffset = max(0, offset)
            }

            actions
        }
        .padding(.horizontal, Spacing.gutterDetail)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(Localization.BookDetails.selectStatus.string, isPresented: $viewModel.isShowingStatusDialog) {
            if case .library(let book) = source {
                ForEach(BookStatus.allCases, id: \.self) { enumStatus in
                    Button(enumStatus.displayName) {
                        Task {
                            await store.updateStatus(book, to: enumStatus)
                        }
                    }
                }
            }
        }
        .alert(Localization.BookDetails.deleteConfirmTitle.string, isPresented: $viewModel.isShowingDeleteAlert) {
            Button(Localization.Generic.delete.string, role: .destructive) {
                if case .library(let book) = source {
                    Task {
                        await store.deleteBook(book)
                        onClose()
                    }
                }
            }
            Button(Localization.Generic.cancel.string, role: .cancel) {}
        } message: {
            Text(Localization.BookDetails.deleteConfirmMessage.string)
        }
        .onAppear {
            switch source {
            case .library(let book):
                viewModel.selectedStatus = book.status
            case .search(let searchBook, _):
                viewModel.alreadyExists = store.contains(searchBook)
            }
        }
        .sheet(isPresented: $showAuth) { AuthSheet() }
        .sheet(isPresented: $isShowingEditForm) {
            if case .library(let book) = source {
                BookFormView(mode: .edit(book))
            }
        }
        .fullScreenCover(item: $addedBook) { book in
            BookAddedView(book: book, onClose: onClose)
        }
        .fullScreenCover(item: $activeReadingBook) { book in
            NavigationStack {
                ReadingSession(selectedBook: book, activeReadingBook: $activeReadingBook)
            }
        }
    }

    // MARK: - Topo

    private var nav: some View {
        HStack {
            ChromeChip(systemImage: "chevron.left", action: onClose)

            Spacer()

            if case .library = source {
                Menu {
                    Button(role: .destructive) {
                        viewModel.isShowingDeleteAlert = true
                    } label: {
                        Label(Localization.BookDetails.deleteBook.string, systemImage: "trash")
                    }

                    Button {
                        isShowingEditForm = true
                    } label: {
                        Label(Localization.BookDetails.editBook.string, systemImage: "pencil")
                    }

                    Button {
                        viewModel.isShowingStatusDialog = true
                    } label: {
                        Label(Localization.BookDetails.changeStatus.string, systemImage: "arrow.trianglehead.2.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.iconLabel)
                        .foregroundStyle(Palette.ink)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.surfaceControl))
                }
            }
        }
        .frame(height: 44)
    }

    // MARK: - Herói

    /// Fração de 0 a 1 do quanto a capa já recolheu.
    private var collapse: CGFloat { min(1, scrollOffset / collapseDistance) }

    private var cover: some View {
        BookCoverView(
            coverUrl: coverURLString,
            width: coverWidth,
            height: coverHeight,
            cornerRadius: Radius.coverLg,
            title: titleText,
            author: authorText
        )
        .coverShadow(.coverHero)
        .hero(heroNamespace, id: heroID)
        .scaleEffect(1 - collapse * 0.25, anchor: .top)
        .opacity(1 - collapse)
        // Sem isto a capa encolhida deixa um buraco: o layout continua a reservar 320pt.
        .frame(height: coverHeight * (1 - collapse * 0.25))
    }

    private var titles: some View {
        VStack(spacing: 6) {
            Text(titleText)
                .textStyle(.titleBook)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)

            Text(authorText)
                .textStyle(.authorRow)
                .foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private var stats: some View {
        HStack(spacing: 22) {
            statColumn(pagesText, Localization.BookDetails.pagesLabel.string)
            statRule
            statColumn(currentPageText, Localization.BookDetails.currentLabel.string)
            statRule
            statColumn(percentDoneText, Localization.BookDetails.doneLabel.string)
        }
        .padding(.vertical, 2)
    }

    private func statColumn(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .textStyle(.titleTertiary)
                .foregroundStyle(Palette.ink)

            Text(label.uppercased())
                .textStyle(.overline)
                .foregroundStyle(Palette.inkFaint)
        }
    }

    private var statRule: some View {
        Rectangle()
            .fill(Palette.rule)
            .frame(width: 1, height: 26)
    }

    @ViewBuilder
    private var description: some View {
        if !cleanedDescription.isEmpty {
            Text(cleanedDescription)
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Ações

    private var actions: some View {
        VStack(spacing: Spacing.md) {
            StatusPill(status: statusBinding)

            switch source {
            case .library:
                if let book = libraryBook {
                    ReadUpButton(title: continueReadingTitle(for: book)) {
                        activeReadingBook = book
                    }
                }

            case .search:
                ReadUpButton(
                    title: addButtonTitle,
                    isLoading: viewModel.isSaving,
                    isEnabled: !viewModel.alreadyExists
                ) {
                    if authManager.isGuest {
                        showAuth = true
                    } else {
                        Task { addedBook = await viewModel.saveBookToLibrary(source: source, store: store) }
                    }
                }

                if let saveMessage = viewModel.saveMessage {
                    Text(saveMessage)
                        .textStyle(.captionFine)
                        .foregroundStyle(Palette.danger)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var addButtonTitle: String {
        viewModel.alreadyExists
            ? Localization.BookDetails.alreadyInLibrary.string
            : Localization.BookDetails.addToLibrary.string
    }

    private func continueReadingTitle(for book: Book) -> String {
        switch book.status {
        case .reading, .rereading: Localization.BookDetails.continueReading.string
        default: Localization.BookDetails.startReading.string
        }
    }

    /// Na biblioteca a mudança de status vai direto ao backend; na busca fica em memória
    /// até o livro ser adicionado.
    private var statusBinding: Binding<BookStatus?> {
        switch source {
        case .library(let book):
            Binding(
                get: { libraryBook?.status },
                set: { new in
                    guard let new else { return }
                    Task { await store.updateStatus(book, to: new) }
                }
            )
        case .search:
            Binding(
                get: { viewModel.selectedStatus },
                set: { viewModel.selectedStatus = $0 ?? .iWantToRead }
            )
        }
    }

    // MARK: - Dados das duas origens

    /// O livro da biblioteca relido do store a cada render.
    ///
    /// A `Source` guarda uma cópia do momento do toque. Enquanto isto era uma sheet,
    /// editar fechava a tela e a cópia velha morria junto; agora a tela fica aberta por
    /// baixo do formulário, e sem reler o store o título e as páginas voltariam com os
    /// valores antigos assim que o formulário saísse.
    private var libraryBook: Book? {
        guard case .library(let book) = source else { return nil }
        return store.books.first { $0.id == book.id } ?? book
    }

    /// O id do herói é o do livro, o mesmo que a capa de origem carrega.
    private var heroID: String {
        switch source {
        case .library(let book): book.id
        case .search(let book, _): book.id
        }
    }

    private var titleText: String {
        switch source {
        case .library: libraryBook?.title ?? ""
        case .search(let book, _): book.title
        }
    }

    private var authorText: String {
        switch source {
        case .library: libraryBook?.author ?? ""
        case .search(let book, _): book.author
        }
    }

    private var coverURLString: String? {
        switch source {
        case .library: libraryBook?.coverUrl
        case .search(let book, _): book.thumbnailURL?.absoluteString
        }
    }

    private var numberOfPages: Int {
        switch source {
        case .library: libraryBook?.numberOfPages ?? 0
        case .search(let book, _): book.numberOfPages
        }
    }

    private var currentPage: Int {
        switch source {
        case .library: libraryBook?.progress ?? 0
        case .search: 0
        }
    }

    private var pagesText: String { numberOfPages > 0 ? "\(numberOfPages)" : "—" }

    private var currentPageText: String { numberOfPages > 0 ? "\(currentPage)" : "—" }

    private var percentDoneText: String {
        guard numberOfPages > 0 else { return "—" }
        return "\(Int((Double(currentPage) / Double(numberOfPages) * 100).rounded()))%"
    }

    private var detailsText: String {
        switch source {
        case .library: libraryBook?.details ?? ""
        case .search(let book, _): book.details
        }
    }

    private var cleanedDescription: String {
        let noHtmlTags = detailsText.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let decodedEntities = noHtmlTags
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        return decodedEntities
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

