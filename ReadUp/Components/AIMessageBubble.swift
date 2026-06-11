import SwiftUI

struct AIMessageBubble: View {
    let message: AIChatMessage
    let service: GoogleBooksService
    
    private var isPortuguese: Bool {
        Locale.current.language.languageCode?.identifier == "pt"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if message.role == .assistant {
                    Text(message.text)
                        .font(.body)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.componentBackground)
                        )
                    Spacer(minLength: 40)
                } else {
                    Spacer(minLength: 40)
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.emphasis)
                        )
                }
            }
            
            if let books = message.recommendedBooks, !books.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(isPortuguese ? "Recomendados para você" : "Recommended for you")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(.secundaryLabel)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(books) { book in
                                NavigationLink(destination: SearchBookDetails(book: book, service: service)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        AsyncImage(url: book.thumbnailURL) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            default:
                                                Color(uiColor: .tertiarySystemFill)
                                            }
                                        }
                                        .frame(width: 100, height: 145)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                        Text(book.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color(uiColor: .label))
                                            .lineLimit(1)

                                        Text(book.author)
                                            .font(.caption)
                                            .foregroundStyle(.secundaryLabel)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 100, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}
