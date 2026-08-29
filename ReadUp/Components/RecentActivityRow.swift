import SwiftUI

struct RecentActivityRow: View {
    let session: LiterarySession
    let formattedDate: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            BookCoverView(coverUrl: session.book.coverUrl, width: 40, height: 56)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.book.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(formattedDate)
                    .font(.bodySupporting)
                    .foregroundStyle(.inkMuted)
            }
            
            Spacer()
            
            Text("+\(session.pagesRead) pages")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.brand)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
    }
}
