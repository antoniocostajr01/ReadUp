import SwiftData
import SwiftUI

struct SearchBookDetails: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var books: [Book]

    let book: SearchBook
    let service: GoogleBooksService

    @State private var selectedStatus: BookStatus = .iWantToRead
    @State private var isSaving = false
    @State private var saveMessage: String?
    @State private var alreadyExists = false
    @State private var isShowingFullDescription = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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

                TitleAndAuthorBook(bookAuthor: book.author, bookTitle: book.title)

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
                    Text("\(book.numberOfPages)")
                }

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
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(.backgroundPrimary)
        .navigationTitle("Book details")
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            alreadyExists = books.contains { $0.title.caseInsensitiveCompare(book.title) == .orderedSame && $0.author.caseInsensitiveCompare(book.author) == .orderedSame }
        }
    }

    private var cleanedDescription: String {
        let raw = book.details
        let noHtmlTags = raw.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let decodedEntities = noHtmlTags
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        let compactedWhitespace = decodedEntities
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return compactedWhitespace
    }

    private var shouldShowReadMore: Bool {
        cleanedDescription.count > 260
    }

    private func saveBookToLibrary() async {
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

#Preview {
    SearchBookDetails(
        book: SearchBook(
            id: "1",
            title: "1984",
            author: "George Orwell",
            details: "A dystopian social science fiction novel.",
            numberOfPages: 328,
            languageCode: "en",
            thumbnailURL: nil
        ),
        service: GoogleBooksService()
    )
}
