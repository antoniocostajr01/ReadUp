import SwiftUI

/// O detalhe de uma linha escaneada. Figma `47:1378` (encontrado) e `47:1414` (não).
///
/// Os dois estados vivem na mesma folha porque são a mesma pergunta — "é este o livro?"
/// — respondida de dois jeitos: confirma e adiciona, ou sai pela busca/cadastro manual.
struct ScannedBookSheet: View {
    let row: ISBNScannerViewModel.ScannedBook
    let viewModel: ISBNScannerViewModel

    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var isAdding = false
    @State private var addedBook: Book?
    @State private var isShowingSearch = false
    @State private var isShowingManualEntry = false

    /// O status vive na linha do scanner, não aqui: fechar a folha não pode perder a escolha.
    private var statusBinding: Binding<BookStatus?> {
        Binding(
            get: { viewModel.scanned.first { $0.id == row.id }?.status },
            set: { new in
                guard let new, let index = viewModel.scanned.firstIndex(where: { $0.id == row.id }) else { return }
                viewModel.scanned[index].status = new
            }
        )
    }

    var body: some View {
        Group {
            if case .found(let book) = row.state {
                foundBody(book)
            } else {
                notFoundBody
            }
        }
        .padding(.horizontal, Spacing.sheetInset)
        .padding(.top, Spacing.sheetInset)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.surface)
        .fullScreenCover(item: $addedBook) { book in
            BookAddedView(book: book) { dismiss() }
        }
        .sheet(isPresented: $isShowingSearch) { Search() }
        .sheet(isPresented: $isShowingManualEntry) {
            BookFormView(mode: .create, prefilledISBN: row.isbn)
        }
    }

    // MARK: - Encontrado. Figma `47:1379`.

    private func foundBody(_ book: SearchBook) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                ChromeChip(systemImage: "xmark") { dismiss() }
                Spacer()
                ChromeChip(systemImage: "checkmark", isFilled: true) { add(book) }
                    .opacity(isAdding ? Motion.disabledOpacity : 1)
                    .disabled(isAdding)
                    .accessibilityLabel(Localization.BookDetails.addToLibrary.string)
            }

            HStack(alignment: .top, spacing: Spacing.cardInset) {
                BookCoverView(
                    coverUrl: book.thumbnailURL?.absoluteString,
                    width: 151,
                    height: 222,
                    cornerRadius: Radius.cover,
                    title: book.title,
                    author: book.author
                )
                .coverShadow(.cover)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark")
                            .font(.captionFine)
                            .foregroundStyle(Palette.onBrand)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Palette.brand))

                        Text(Localization.Scan.bookFound.string.uppercased())
                            .textStyle(.overline)
                            .foregroundStyle(Palette.inkSoft)
                    }

                    Text(book.title)
                        .textStyle(.displayMetric)
                        .foregroundStyle(Palette.ink)

                    Text(book.author)
                        .textStyle(.authorRow)
                        .foregroundStyle(Palette.inkSoft)

                    if book.numberOfPages > 0 {
                        Text(Localization.Search.pageCount(book.numberOfPages))
                            .textStyle(.captionDefault)
                            .foregroundStyle(Palette.inkMeta)
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !book.details.isEmpty {
                Text(book.details)
                    .textStyle(.bodyDefault)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(4)
            }

            VStack(spacing: 0) {
                specRow(Localization.AddBook.isbnLabel.string, row.isbn)
                specRow(Localization.BookDetails.pagesLabel.string,
                        book.numberOfPages > 0 ? "\(book.numberOfPages)" : "—")
                specRow(Localization.AddBook.startingPageLabel.string, "1")
                Rectangle().fill(Palette.divider).frame(height: 1)
            }

            StatusPill(status: statusBinding)

            Spacer(minLength: Spacing.lg)

            Text(Localization.Scan.catalogNote.string)
                .textStyle(.captionFine)
                .foregroundStyle(Palette.inkMeta)
        }
    }

    /// Figma `47:1400`: rótulo em overline à esquerda, valor à direita, filete no topo.
    private func specRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .textStyle(.overline)
                .foregroundStyle(Palette.inkFaint)

            Spacer()

            Text(value)
                .textStyle(.label)
                .foregroundStyle(Palette.ink)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.divider).frame(height: 1)
        }
    }

    private func add(_ book: SearchBook) {
        isAdding = true
        Task {
            let status = statusBinding.wrappedValue ?? .iWantToRead
            addedBook = await store.addBook(from: book, status: status, isbn: row.isbn)
            isAdding = false
            if addedBook != nil { viewModel.remove(row) }
        }
    }

    // MARK: - Não encontrado. Figma `47:1414`.

    private var notFoundBody: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                ChromeChip(systemImage: "xmark") { dismiss() }
                Spacer()
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(Localization.Scan.barcodeRead.string.uppercased())
                    .textStyle(.overline)
                    .foregroundStyle(Palette.inkFaint)

                Text(row.isbn)
                    .textStyle(.titleSecondary)
                    .foregroundStyle(Palette.ink)
            }

            // O aviso é âmbar, não vermelho: o scan funcionou, o catálogo é que não tem
            // o livro. Nada falhou do lado do usuário.
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.iconInline)
                    .foregroundStyle(Palette.warning)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Localization.Scan.notInCatalogTitle.string)
                        .textStyle(.label)
                        .foregroundStyle(Palette.warningInk)

                    Text(Localization.Scan.notInCatalogMessage.string)
                        .textStyle(.captionFine)
                        .foregroundStyle(Palette.warningInkSoft)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.cardInset)
            .background(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .fill(Palette.warningSurface)
            )

            Spacer(minLength: Spacing.lg)

            VStack(spacing: Spacing.md) {
                ReadUpButton(title: Localization.Scan.searchByTitle.string) {
                    isShowingSearch = true
                }
                ReadUpButton(title: Localization.Scan.enterManually.string, variant: .secondary) {
                    isShowingManualEntry = true
                }
            }
        }
    }
}
