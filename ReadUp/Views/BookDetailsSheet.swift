import SwiftData
import SwiftUI

struct BookDetailsSheet: View {
    enum Source {
        case library(Book)
        case search(SearchBook, GoogleBooksService)
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var books: [Book]

    let source: Source

    @State private var viewModel = BookDetailsSheetViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    coverView

                    TitleAndAuthorBook(bookAuthor: authorText, bookTitle: titleText)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(cleanedDescription)
                            .font(.body)
                            .lineSpacing(2)
                            .lineLimit(viewModel.isShowingFullDescription ? nil : 5)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if shouldShowReadMore {
                            Button(viewModel.isShowingFullDescription ? "Read less" : "Read more") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.isShowingFullDescription.toggle()
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.emphasis)
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "book.pages.fill")
                        Text("\(pagesText)")
                    }

                    switch source {
                    case .library(let book):
                        HStack {
                            Text(book.status.rawValue)
                                .foregroundStyle(.mainText)
                                .font(.system(.title3, weight: .semibold))
                        }
                        .frame(width: 297, height: 61)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.emphasis, lineWidth: 2)
                        )

                    case .search:
                        Picker("Status", selection: $viewModel.selectedStatus) {
                            ForEach(BookStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 297, height: 61)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.emphasis, lineWidth: 2)
                        )

                        Button {
                            Task { await viewModel.saveBookToLibrary(source: source, modelContext: modelContext, onDismiss: { dismiss() }) }
                        } label: {
                            Text(viewModel.alreadyExists ? "Already in library" : (viewModel.isSaving ? "Saving..." : "Add to library"))
                                .font(.system(.title3, weight: .semibold))
                                .foregroundStyle(.componentBackground)
                                .frame(width: 361, height: 61)
                                .background(
                                    RoundedRectangle(cornerRadius: 50)
                                        .foregroundStyle(viewModel.alreadyExists ? .secundaryLabel : .emphasis)
                                )
                        }
                        .disabled(viewModel.alreadyExists || viewModel.isSaving)

                        if let saveMessage = viewModel.saveMessage {
                            Text(saveMessage)
                                .font(.footnote)
                                .foregroundStyle(.secundaryLabel)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(.backgroundPrimary)
            .navigationTitle("Book details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .library = source {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                viewModel.isShowingDeleteAlert = true
                            } label: {
                                Label("Delete Book", systemImage: "trash.fill")
                            }

                            Button {
                                viewModel.isShowingStatusDialog = true
                            } label: {
                                Label("Change Status", systemImage: "arrow.trianglehead.2.clockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog("Select a status to this book", isPresented: $viewModel.isShowingStatusDialog) {
                if case .library(let book) = source {
                    ForEach(BookStatus.allCases, id: \.self) { enumStatus in
                        Button(enumStatus.rawValue) {
                            book.status = enumStatus
                        }
                    }
                }
            }
            .alert("Are you sure you want to delete this book?", isPresented: $viewModel.isShowingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteLibraryBookIfNeeded(source: source, modelContext: modelContext, onDismiss: { dismiss() })
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your book and your progress will be deleted.")
            }
            .onAppear {
                if case .search(let searchBook, _) = source {
                    viewModel.alreadyExists = books.contains {
                        $0.title.caseInsensitiveCompare(searchBook.title) == .orderedSame &&
                        $0.author.caseInsensitiveCompare(searchBook.author) == .orderedSame
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
            if let image = UIImage(data: book.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 148, height: 211)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        case .search(let book, _):
            AsyncImage(url: book.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color.tabBarBackground
                }
            }
            .frame(width: 148, height: 211)
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
