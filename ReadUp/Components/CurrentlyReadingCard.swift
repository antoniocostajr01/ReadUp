import SwiftUI

struct CurrentlyReadingCard: View {
    let book: Book
    let progressValue: Double
    /// Capa já baixada (cache da `LibraryStore`). Se presente, é exibida direto, sem `AsyncImage`.
    var coverData: Data? = nil
    let onStartReading: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                coverView
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secundaryLabel)
                        .lineLimit(1)
                    Text(book.title)
                        .font(.system(.title3, weight: .bold))
                        .lineLimit(2)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secundaryLabel)
                        .lineLimit(1)
                    
                    let currentProgress = max(0, book.progress ?? 0)
                    let totalPages = max(1, book.numberOfPages)
                    let percentage = Int((Double(currentProgress) / Double(totalPages) * 100).rounded())
                    
                    HStack {
                        Text(String(format: Localization.Components.pageOf.string, currentProgress, book.numberOfPages))
                            .font(.subheadline)
                            .foregroundStyle(.secundaryLabel)
                        Spacer()
                        Text("\(min(percentage, 100))%")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(.emphasis)
                    }
                    .padding(.top, 4)
                }
            }
            
            ProgressView(value: progressValue)
                .tint(.emphasis)
            
            Button(action: onStartReading) {
                Text((book.progress ?? 0) == 0 ? Localization.Components.startReading.string : Localization.Components.continueReading.string)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.emphasis)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    /// Mostra a capa do cache (estável) ou cai no `BookCoverView` (AsyncImage) se ainda não baixada.
    @ViewBuilder
    private var coverView: some View {
        if let coverData, let image = UIImage(data: coverData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 86, height: 124)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            BookCoverView(coverUrl: book.coverUrl, width: 86, height: 124)
        }
    }
}
