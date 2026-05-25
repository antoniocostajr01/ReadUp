import SwiftUI
import SwiftData
import Foundation

struct SessionSummary: View {
    @Environment(\.modelContext) private var modelContextSessions
    @Environment(\.dismiss) private var dismiss

    @State var readingTime: Int
    @State var currentBook: Book
    @State var pagesRead: Int
    @State var thoughts: String = ""

    var onSessionSaved: (() -> Void)? = nil
    @State var sessionToEdit: LiterarySession?

    private func setupForEditting() {
        if let session = sessionToEdit {
            pagesRead = session.pagesRead
            currentBook = session.book
            thoughts = session.thoughts
            readingTime = session.timeRead
        }
    }

    private var completionPercentage: Int {
        guard currentBook.numberOfPages > 0 else { return 0 }
        let progress = Double(currentBook.progress ?? 0)
        return Int(((progress / Double(currentBook.numberOfPages)) * 100).rounded())
    }

    private var sessionMinutes: Int {
        max(1, readingTime / 60)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard

                totalProgressCard

                HStack(spacing: 10) {
                    statCard(icon: "timer", title: "Session Time", value: "\(sessionMinutes) mins")
                    statCard(icon: "chart.line.uptrend.xyaxis", title: "Total Completion", value: "\(completionPercentage)%")
                }

                Text("Final Thoughts")
                    .font(.system(.title3, weight: .bold))

                TextField("Capture any lingering thoughts from this session...", text: $thoughts, axis: .vertical)
                    .lineLimit(5...10)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )

                Button(action: saveSession) {
                    Label("Save Session", systemImage: "square.and.arrow.down")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.emphasis)
                        )
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(.backgroundPrimary)
        .navigationTitle("Session Summary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setupForEditting)
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

                Text(currentBook.author)
                    .font(.title3)
                    .foregroundStyle(.secundaryLabel)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
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
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func saveSession() {
        let session = LiterarySession(book: currentBook, pagesRead: pagesRead, progress: pagesRead, timeRead: readingTime, thoughts: thoughts)
        modelContextSessions.insert(session)

        do {
            try modelContextSessions.save()
            onSessionSaved?()
            dismiss()
        } catch {
            print("Failed to save session")
        }
    }
}
