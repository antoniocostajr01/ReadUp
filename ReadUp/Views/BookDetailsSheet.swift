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

    @State private var isShowingStatusDialog = false
    @State private var isShowingDeleteAlert = false
    @State private var selectedStatus: BookStatus = .iWantToRead
    @State private var isSaving = false
    @State private var saveMessage: String?
    @State private var alreadyExists = false
    @State private var isShowingFullDescription = false

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
                            .lineLimit(isShowingFullDescription ? nil : 5)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if shouldShowReadMore {
                            Button(isShowingFullDescription ? "Read less" : "Read more") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isShowingFullDescription.toggle()
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
                        Picker("Status", selection: $selectedStatus) {
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
                            Task { await saveBookToLibrary() }
                        } label: {
                            Text(alreadyExists ? "Already in library" : (isSaving ? "Saving..." : "Add to library"))
                                .font(.system(.title3, weight: .semibold))
                                .foregroundStyle(.componentBackground)
                                .frame(width: 361, height: 61)
                                .background(
                                    RoundedRectangle(cornerRadius: 50)
                                        .foregroundStyle(alreadyExists ? .secundaryLabel : .emphasis)
                                )
                        }
                        .disabled(alreadyExists || isSaving)

                        if let saveMessage {
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
                                isShowingDeleteAlert = true
                            } label: {
                                Label("Delete Book", systemImage: "trash.fill")
                            }

                            Button {
                                isShowingStatusDialog = true
                            } label: {
                                Label("Change Status", systemImage: "arrow.trianglehead.2.clockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog("Select a status to this book", isPresented: $isShowingStatusDialog) {
                if case .library(let book) = source {
                    ForEach(BookStatus.allCases, id: \.self) { enumStatus in
                        Button(enumStatus.rawValue) {
                            book.status = enumStatus
                        }
                    }
                }
            }
            .alert("Are you sure you want to delete this book?", isPresented: $isShowingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteLibraryBookIfNeeded()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your book and your progress will be deleted.")
            }
            .onAppear {
                if case .search(let searchBook, _) = source {
                    alreadyExists = books.contains {
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

    private func deleteLibraryBookIfNeeded() {
        guard case .library(let book) = source else { return }

        do {
            let bookIdToDelete = book.id
            let predicate = #Predicate<LiterarySession> { session in
                session.book.id == bookIdToDelete
            }
            let descriptor = FetchDescriptor<LiterarySession>(predicate: predicate)
            let sessionsToDelete = try modelContext.fetch(descriptor)

            for session in sessionsToDelete {
                modelContext.delete(session)
            }

            modelContext.delete(book)
            try modelContext.save()
            dismiss()
        } catch {
            print("Falha ao deletar as sessões: \(error.localizedDescription)")
        }
    }

    private func saveBookToLibrary() async {
        guard case .search(let book, let service) = source else { return }

        isSaving = true
        defer { isSaving = false }

        let imageData = await service.loadImageData(from: book.thumbnailURL) ?? Data()
        let newBook = Book(
            title: book.title,
            author: book.author,
            numberOfPages: book.numberOfPages,
            details: book.details,
            status: selectedStatus,
            imageData: imageData
        )

        modelContext.insert(newBook)

        do {
            try modelContext.save()
            saveMessage = "Book added successfully."
            alreadyExists = true
            dismiss()
        } catch {
            saveMessage = "Could not save this book."
        }
    }
}
