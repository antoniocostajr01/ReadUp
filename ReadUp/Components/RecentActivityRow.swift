import SwiftUI

struct RecentActivityRow: View {
    let session: LiterarySession
    let formattedDate: String

    var body: some View {
        HStack(spacing: 12) {
            BookCoverView(data: session.book.imageData, width: 40, height: 56)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.book.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secundaryLabel)
            }
            
            Spacer()
            
            Text("+\(session.pagesRead) pages")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.emphasis)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
