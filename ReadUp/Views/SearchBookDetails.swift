import SwiftData
import SwiftUI

struct SearchBookDetails: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var books: [Book]

    let book: SearchBook
    let service: GoogleBooksService

    @State private var viewModel = SearchBookDetailsViewModel()

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
                    Text("\(book.numberOfPages)")
                }

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
                    Task { await viewModel.saveBookToLibrary(book: book, service: service, modelContext: modelContext, onDismiss: { dismiss() }) }
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
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(.backgroundPrimary)
        .navigationTitle("Book details")
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.alreadyExists = books.contains { $0.title.caseInsensitiveCompare(book.title) == .orderedSame && $0.author.caseInsensitiveCompare(book.author) == .orderedSame }
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
