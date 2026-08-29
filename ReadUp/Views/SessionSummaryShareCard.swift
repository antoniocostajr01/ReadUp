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
        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            .fill(Color.surfaceRaised.opacity(0.7))
    }
    
    var body: some View {
        VStack(spacing: Spacing.cardInset) {
            headerCard
            
            totalProgressCard
            
            HStack(spacing: 10) {
                ShareStatCard(icon: "book.pages", title: "Pages Read", value: "\(sessionPagesRead)")
                ShareStatCard(icon: "timer", title: "Session Time", value: sessionTime)
            }
            
            footerCard
        }
        .padding(Spacing.xl)
        .background(Color.clear)
        .frame(width: 380)
    }
    
    private var headerCard: some View {
        HStack(spacing: Spacing.cardInset) {
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
                    .font(.titleSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Color.ink)

                Text(currentBook.author)
                    .font(.title3)
                    .foregroundStyle(.inkMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.cardInset)
        .background(cardBackground)
    }

    /// Assinatura do leitor: foto e nome do perfil.
    private var footerCard: some View {
        HStack(spacing: Spacing.md) {
            if let userAvatar {
                Image(uiImage: userAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.brand)
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(.system(.headline, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(Color.ink)

                Text("ReadUp")
                    .font(.bodySupporting)
                    .foregroundStyle(.inkMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.cardInset)
        .background(cardBackground)
    }

    private var totalProgressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Total Progress", systemImage: "book")
                .font(.bodySupporting)
                .foregroundStyle(.inkMuted)
            
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("\(totalProgress)")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(.brand)
                Text("/ \(currentBook.numberOfPages) pages")
                    .font(.title3)
                    .foregroundStyle(.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .background(cardBackground)
    }
}

fileprivate struct ShareStatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: icon)
                .font(.bodySupporting)
                .foregroundStyle(.inkMuted)

            Text(value)
                .font(.titlePrimary)
                .foregroundStyle(.brand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(Color.surfaceRaised.opacity(0.7))
        )
    }
}
