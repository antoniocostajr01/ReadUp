import SwiftUI

struct BookDetailsSheet: View {
    enum Source {
        case library(Book)
        case search(SearchBook, GoogleBooksService)
    }

    @Environment(LibraryStore.self) private var store
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    let source: Source

    @State private var viewModel = BookDetailsSheetViewModel()
    @State private var showAuth = false
    @State private var isShowingEditForm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    coverView

                    TitleAndAuthorBook(bookAuthor: authorText, bookTitle: titleText)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(cleanedDescription)
                            .font(.bodyDefault)
                            .lineSpacing(2)
                            .lineLimit(viewModel.isShowingFullDescription ? nil : 5)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if shouldShowReadMore {
                            Button(viewModel.isShowingFullDescription ? Localization.BookDetails.readLess.string : Localization.BookDetails.readMore.string) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.isShowingFullDescription.toggle()
                                }
                            }
                            .font(.bodySupportingStrong)
                            .foregroundStyle(.brand)
                        }
                    }

                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "book.pages.fill")
                        Text("\(pagesText)")
                    }

                    switch source {
                    case .library(let book):
                        HStack {
                            Text(book.status.displayName)
                                .foregroundStyle(.ink)
                                .font(.titleTertiary)
                        }
                        .frame(width: 297, height: 61)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(.brand, lineWidth: 2)
                        )

                    case .search:
                        Picker("Status", selection: $viewModel.selectedStatus) {
                            ForEach(BookStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 297, height: 61)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(.brand, lineWidth: 2)
                        )

                        Button {
                            if authManager.isGuest {
                                showAuth = true
                            } else {
                                Task { await viewModel.saveBookToLibrary(source: source, store: store, onDismiss: { dismiss() }) }
                            }
                        } label: {
                            Text(viewModel.alreadyExists ? Localization.BookDetails.alreadyInLibrary.string : (viewModel.isSaving ? Localization.BookDetails.saving.string : Localization.BookDetails.addToLibrary.string))
                                .font(.titleTertiary)
                                .foregroundStyle(.white)
                                .frame(width: 361, height: 61)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.pill)
                                        .foregroundStyle(viewModel.alreadyExists ? .inkMuted : .brand)
                                )
                        }
                        .disabled(viewModel.alreadyExists || viewModel.isSaving)

                        if let saveMessage = viewModel.saveMessage {
                            Text(saveMessage)
                                .font(.captionDefault)
                                .foregroundStyle(.inkMuted)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, 20)
            }
            .background(.surface)
            .navigationTitle(Localization.BookDetails.title.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .library = source {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                viewModel.isShowingDeleteAlert = true
                            } label: {
                                Label(Localization.BookDetails.deleteBook.string, systemImage: "trash.fill")
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
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog(Localization.BookDetails.selectStatus.string, isPresented: $viewModel.isShowingStatusDialog) {
                if case .library(let book) = source {
                    ForEach(BookStatus.allCases, id: \.self) { enumStatus in
                        Button(enumStatus.displayName) {
                            Task {
                                await store.updateStatus(book, to: enumStatus)
                                dismiss()
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
                            dismiss()
                        }
                    }
                }
                Button(Localization.Generic.cancel.string, role: .cancel) {}
            } message: {
                Text(Localization.BookDetails.deleteConfirmMessage.string)
            }
            .onAppear {
                if case .search(let searchBook, _) = source {
                    viewModel.alreadyExists = store.contains(searchBook)
                }
            }
            .sheet(isPresented: $showAuth) {
                AuthSheet()
            }
            .sheet(isPresented: $isShowingEditForm) {
                if case .library(let book) = source {
                    BookFormView(mode: .edit(book)) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var titleText: String {
        switch source {
        case .library(let book): return book.title
        case .search(let book, _): return book.title
        }
    }

    private var authorText: String {
        switch source {
        case .library(let book): return book.author
        case .search(let book, _): return book.author
        }
    }

    private var pagesText: Int {
        switch source {
        case .library(let book): return book.numberOfPages
        case .search(let book, _): return book.numberOfPages
        }
    }

    private var detailsText: String {
        switch source {
        case .library(let book): return book.details
        case .search(let book, _): return book.details
        }
    }

    @ViewBuilder
    private var coverView: some View {
        switch source {
        case .library(let book):
            BookCoverView(coverUrl: book.coverUrl, width: 148, height: 211, cornerRadius: Radius.md)
        case .search(let book, _):
            AsyncImage(url: book.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color.surfaceChrome
                }
            }
            .frame(width: 148, height: 211)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
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

    private var shouldShowReadMore: Bool {
        cleanedDescription.count > 260
    }
}
