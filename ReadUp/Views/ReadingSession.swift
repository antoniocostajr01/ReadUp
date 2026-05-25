import SwiftUI

struct ReadingSession: View {
    let selectedBook: Book
    @Binding var activeReadingBook: Book?

    @State private var viewModel = ReadingSessionViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                coverView

                VStack(spacing: 4) {
                    Text("READING SESSION")
                        .font(.caption)
                        .foregroundStyle(.emphasis)
                        .tracking(1.2)

                    Text(selectedBook.title)
                        .font(.system(.largeTitle, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(selectedBook.author)
                        .font(.title3)
                        .italic()
                        .foregroundStyle(.secundaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)

                timerCircle

                HStack(spacing: 10) {
                    SmallMetricCard(title: "PAGES READ", value: "\(viewModel.pagesReadInSession(selectedBook: selectedBook))")
                    SmallMetricCard(title: "CURRENT PAGE", value: "\(selectedBook.progress ?? 0)")
                }

                Button {
                    viewModel.isShowingAlertValue = true
                } label: {
                    Label("Finish", systemImage: "checkmark.circle")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.emphasis)
                        )
                }
                .disabled(!viewModel.isSessionRunning)
                .opacity(viewModel.isSessionRunning ? 1 : 0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(.backgroundPrimary)
        .navigationTitle("Reading Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.startCountdown()
        }
        .onDisappear {
            viewModel.stopAllTimers()
        }
        .alert("Which page did you leave off?", isPresented: $viewModel.isShowingAlertValue) {
            TextField("Page", text: $viewModel.lastPageRead)
                .keyboardType(.numberPad)

            Button("Confirm") {
                if let page = Int(viewModel.lastPageRead) {
                    selectedBook.progress = page
                    viewModel.isShowingSummary = true
                }
            }

            Button("Cancel", role: .cancel) {
                viewModel.lastPageRead = ""
            }
        }
        .navigationDestination(isPresented: $viewModel.isShowingSummary) {
            SessionSummary(
                readingTime: viewModel.timeElapsed,
                currentBook: selectedBook,
                pagesRead: Int(viewModel.lastPageRead) ?? selectedBook.progress ?? 0,
                thoughts: "",
                onSessionSaved: {
                    activeReadingBook = nil
                }
            )
        }
    }

    private var coverView: some View {
        Group {
            if let bookCover = UIImage(data: selectedBook.imageData) {
                Image(uiImage: bookCover)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(uiColor: .tertiarySystemFill)
            }
        }
        .frame(width: 130, height: 184)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(Color(uiColor: .quaternaryLabel), lineWidth: 10)

            Circle()
                .trim(from: 0, to: min(CGFloat(viewModel.timeElapsed % 3600) / 3600, 1))
                .stroke(Color.emphasis, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(Color(uiColor: .secondarySystemBackground))
                .padding(24)

            if viewModel.isSessionRunning {
                Text(viewModel.timeString(from: viewModel.timeElapsed))
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
            } else {
                Text("\(viewModel.countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.emphasis)
            }
        }
        .frame(width: 300, height: 300)
        .padding(.top, 8)
    }



}
