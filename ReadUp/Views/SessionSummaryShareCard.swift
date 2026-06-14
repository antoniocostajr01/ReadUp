import SwiftUI

struct SessionSummaryShareCard: View {
    let currentBook: Book
    let sessionPagesRead: Int
    let sessionMinutes: Int
    let completionPercentage: Int
    
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
                ShareStatCard(icon: "timer", title: "Session Time", value: "\(sessionMinutes) mins")
            }
            
            HStack(spacing: 10) {
                ShareStatCard(icon: "chart.line.uptrend.xyaxis", title: "Total Completion", value: "\(completionPercentage)%")
            }
        }
        .padding(24)
        .background(Color.clear)
        .frame(width: 380)
    }
    
    private var headerCard: some View {
        HStack(spacing: 14) {
            if let bookCover = UIImage(data: currentBook.imageData) {
                Image(uiImage: bookCover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(currentBook.title)
                    .font(.system(.title2, weight: .bold))
                    .lineLimit(2)
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(currentBook.author)
                    .font(.title3)
                    .foregroundStyle(.secundaryLabel)
                    .lineLimit(1)
            }
            Spacer()
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
                Text("\(currentBook.progress ?? 0)")
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
