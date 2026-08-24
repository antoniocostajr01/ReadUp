import SwiftUI

struct SessionSummaryShareCard: View {
    let currentBook: Book
    let coverImage: UIImage?
    let sessionPagesRead: Int
    let sessionTime: String
    let totalProgress: Int
    let userName: String
    let userAvatar: UIImage?

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground).opacity(0.7))
    }
    
    var body: some View {
        VStack(spacing: 14) {
            headerCard
            
            totalProgressCard
            
            HStack(spacing: 10) {
                ShareStatCard(icon: "book.pages", title: "Pages Read", value: "\(sessionPagesRead)")
                ShareStatCard(icon: "timer", title: "Session Time", value: sessionTime)
            }
            
            footerCard
        }
        .padding(24)
        .background(Color.clear)
        .frame(width: 380)
    }
    
    private var headerCard: some View {
        HStack(spacing: 14) {
            if let coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Título completo: sem lineLimit, o card cresce se precisar.
                Text(currentBook.title)
                    .font(.system(.title2, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Color(uiColor: .label))

                Text(currentBook.author)
                    .font(.title3)
                    .foregroundStyle(.secundaryLabel)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(cardBackground)
    }

    /// Assinatura do leitor: foto e nome do perfil.
    private var footerCard: some View {
        HStack(spacing: 12) {
            if let userAvatar {
                Image(uiImage: userAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.emphasis)
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(.system(.headline, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(Color(uiColor: .label))

                Text("ReadUp")
                    .font(.subheadline)
                    .foregroundStyle(.secundaryLabel)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(cardBackground)
    }

    private var totalProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Total Progress", systemImage: "book")
                .font(.subheadline)
                .foregroundStyle(.secundaryLabel)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(totalProgress)")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(.emphasis)
                Text("/ \(currentBook.numberOfPages) pages")
                    .font(.title3)
                    .foregroundStyle(.secundaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }
}

fileprivate struct ShareStatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secundaryLabel)

            Text(value)
                .font(.system(.title, weight: .bold))
                .foregroundStyle(.emphasis)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground).opacity(0.7))
        )
    }
}
