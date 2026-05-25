import SwiftUI
import SwiftData
import Foundation

struct SessionSummary: View {
    @Environment(\.modelContext) private var modelContextSessions
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SessionSummaryViewModel
    var onSessionSaved: (() -> Void)? = nil

    init(readingTime: Int, currentBook: Book, pagesRead: Int, thoughts: String = "", onSessionSaved: (() -> Void)? = nil, sessionToEdit: LiterarySession? = nil) {
        self.onSessionSaved = onSessionSaved
        self._viewModel = State(initialValue: SessionSummaryViewModel(readingTime: readingTime, currentBook: currentBook, pagesRead: pagesRead, sessionToEdit: sessionToEdit))
        self.viewModel.thoughts = thoughts
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard

                totalProgressCard

                HStack(spacing: 10) {
                    StatCard(icon: "timer", title: "Session Time", value: "\(viewModel.sessionMinutes) mins")
                    StatCard(icon: "chart.line.uptrend.xyaxis", title: "Total Completion", value: "\(viewModel.completionPercentage)%")
                }

                Text("Final Thoughts")
                    .font(.system(.title3, weight: .bold))

                TextField("Capture any lingering thoughts from this session...", text: $viewModel.thoughts, axis: .vertical)
                    .lineLimit(5...10)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )

                Button(action: {
                    viewModel.saveSession(modelContext: modelContextSessions, onSessionSaved: onSessionSaved, onDismiss: { dismiss() })
                }) {
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
        .toolbar(.hidden, for: .tabBar)
        .onAppear(perform: viewModel.setupForEditting)
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            if let bookCover = UIImage(data: viewModel.currentBook.imageData) {
                Image(uiImage: bookCover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.currentBook.title)
                    .font(.system(.title2, weight: .bold))
                    .lineLimit(2)

                Text(viewModel.currentBook.author)
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
                Text("\(viewModel.currentBook.progress ?? 0)")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(.emphasis)
                Text("/ \(viewModel.currentBook.numberOfPages) pages")
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



}
