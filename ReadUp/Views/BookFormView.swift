import PhotosUI
import SwiftUI

/// Um formulário, dois modos: cadastro manual (vazio) e edição (pré-preenchido).
/// Figma `47:1754`. Ver `.claude/specs/2026-08-05-book-search-and-entry-design.md`.
///
/// Não é um `Form`: o desenho pede campos sublinhados sobre creme, sem os agrupamentos
/// e o fundo cinza que a lista do sistema impõe.
struct BookFormView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: BookFormViewModel
    @State private var addedBook: Book?
    let onSaved: () -> Void

    init(mode: BookFormViewModel.Mode, onSaved: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: BookFormViewModel(mode: mode))
        self.onSaved = onSaved
    }

    private var isCreating: Bool {
        if case .create = viewModel.mode { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            nav

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.cardInset) {
                    Text(isCreating
                         ? Localization.AddBook.screenTitle.string
                         : Localization.BookDetails.editBook.string)
                        .textStyle(.titlePrimary)
                        .foregroundStyle(Palette.ink)

                    identityRow
                    pagesRow

                    UnderlinedField(
                        label: Localization.AddBook.isbnLabel.string,
                        text: $viewModel.isbn,
                        keyboardType: .numbersAndPunctuation
                    )

                    descriptionField
                    StatusPill(status: statusBinding)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .textStyle(.captionFine)
                            .foregroundStyle(Palette.danger)
                    }
                }
                .padding(.top, Spacing.cardInset)
                .padding(.bottom, Spacing.lg)
            }
            .scrollIndicators(.never)

            footer
        }
        .padding(.horizontal, 22)
        .padding(.top, Spacing.sm)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.selectedPhoto) { _, item in
            Task { await viewModel.handlePhotoSelection(item) }
        }
        .fullScreenCover(item: $addedBook) { book in
            BookAddedView(book: book) { dismiss() }
        }
    }

    // MARK: - Chrome

    /// Figma `47:1758`: voltar, o rótulo da tela em overline, e o ✓ que confirma.
    private var nav: some View {
        HStack {
            ChromeChip(systemImage: "chevron.left") { dismiss() }

            Spacer()

            Text(Localization.AddBook.manualEntry.string.uppercased())
                .textStyle(.overline)
                .foregroundStyle(Palette.inkFaint)

            Spacer()

            ChromeChip(systemImage: "checkmark", isFilled: true, action: save)
                .opacity(viewModel.isSaveEnabled && !viewModel.isSaving ? 1 : Motion.disabledOpacity)
                .disabled(!viewModel.isSaveEnabled || viewModel.isSaving)
                .accessibilityLabel(Localization.AddBook.saveBook.string)
        }
        .frame(height: 36)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Localization.AddBook.pageCountNote.string)
                .textStyle(.captionFine)
                .foregroundStyle(Palette.inkMeta)

            ReadUpButton(
                title: Localization.BookDetails.addToLibrary.string,
                isLoading: viewModel.isSaving,
                isEnabled: viewModel.isSaveEnabled,
                action: save
            )
        }
    }

    private func save() {
        Task {
            guard await viewModel.save(store: store) else { return }
            onSaved()
            // O cadastro manual também termina na conquista; a edição só fecha.
            if let created = viewModel.createdBook {
                addedBook = created
            } else {
                dismiss()
            }
        }
    }

    // MARK: - Campos

    /// Capa opcional à esquerda, título e autor à direita. Figma `47:1765`.
    private var identityRow: some View {
        HStack(alignment: .top, spacing: Spacing.cardInset) {
            coverPicker

            VStack(alignment: .leading, spacing: Spacing.cardInset) {
                UnderlinedField(
                    label: Localization.AddBook.titlePlaceholder.string,
                    text: $viewModel.title,
                    isRequired: true,
                    autocapitalization: .words
                )

                UnderlinedField(
                    label: Localization.AddBook.authorPlaceholder.string,
                    text: $viewModel.author,
                    isRequired: true,
                    autocapitalization: .words
                )
            }
        }
    }

    private var pagesRow: some View {
        HStack(alignment: .top, spacing: Spacing.cardInset) {
            UnderlinedField(
                label: Localization.BookDetails.pagesLabel.string,
                text: $viewModel.pagesText,
                isRequired: true,
                keyboardType: .numberPad
            )

            UnderlinedField(
                label: Localization.AddBook.startingPageLabel.string,
                text: $viewModel.startingPageText,
                keyboardType: .numberPad
            )
        }
    }

    /// Figma `47:1791`: o único campo em caixa, porque é multilinha.
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Localization.AddBook.descriptionLabel.string.uppercased())
                .textStyle(.overline)
                .foregroundStyle(Palette.inkFaint)

            TextEditor(text: $viewModel.details)
                .textStyle(.bodyDefault)
                .foregroundStyle(Palette.ink)
                .scrollContentBackground(.hidden)
                .frame(height: 74)
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                        .strokeBorder(Palette.border, lineWidth: 1)
                )
        }
    }

    private var statusBinding: Binding<BookStatus?> {
        Binding(
            get: { viewModel.status },
            set: { viewModel.status = $0 ?? .iWantToRead }
        )
    }

    /// Figma `47:1766`: um retângulo tracejado enquanto não há capa.
    private var coverPicker: some View {
        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images, photoLibrary: .shared()) {
            Group {
                if let image = viewModel.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.cover, style: .continuous))
                } else if let existingUrl = viewModel.mode.book?.coverUrl {
                    BookCoverView(coverUrl: existingUrl, width: 76, height: 110, cornerRadius: Radius.cover)
                } else {
                    VStack(spacing: 5) {
                        Text(verbatim: "+")
                            .textStyle(.titleTertiary)
                            .foregroundStyle(Palette.inkFainter)

                        Text(Localization.AddBook.coverOptional.string)
                            .textStyle(.overline)
                            .foregroundStyle(Palette.inkFaint)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 76, height: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.cover, style: .continuous)
                            .strokeBorder(
                                Palette.ink.opacity(0.26),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                            )
                    )
                }
            }
        }
        .disabled(viewModel.isSaving)
        .accessibilityLabel(Localization.AddBook.accessGallery.string)
    }
}

#Preview {
    BookFormView(mode: .create)
        .environment(LibraryStore())
}
