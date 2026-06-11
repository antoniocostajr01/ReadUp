import SwiftUI

struct ReadingSession: View {
    let selectedBook: Book
    @Binding var activeReadingBook: Book?

    @State private var viewModel = ReadingSessionViewModel()
    @State private var showValidationError = false
    @State private var validationMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            coverView

            VStack(spacing: 4) {
                Text("READING SESSION")
                    .font(.caption)
                    .foregroundStyle(.emphasis)
                    .tracking(1.2)

                Text(selectedBook.title)
                    .font(.system(.title, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(selectedBook.author)
                    .font(.title3)
                    .italic()
                    .foregroundStyle(.secundaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            // Timer simples sem círculo de progresso
            VStack(spacing: 4) {
                if viewModel.isSessionRunning {
                    Text(viewModel.timeString(from: viewModel.timeElapsed))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text("\(viewModel.countdown)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.emphasis)
                }

                SmallMetricCard(title: "CURRENT PAGE", value: "\(selectedBook.progress ?? 0)")
            }

            Spacer()

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
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
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
                    let currentProgress = selectedBook.progress ?? 0

                    if page < currentProgress {
                        validationMessage = "You can't go back! Your current progress is page \(currentProgress)."
                        showValidationError = true
                        return
                    }

                    if page > selectedBook.numberOfPages {
                        validationMessage = "This book only has \(selectedBook.numberOfPages) pages."
                        showValidationError = true
                        return
                    }

                    // Salva progresso anterior antes de atualizar
                    viewModel.previousProgress = currentProgress
                    selectedBook.progress = page
                    viewModel.isShowingSummary = true
                }
            }

            Button("Cancel", role: .cancel) {
                viewModel.lastPageRead = ""
            }
        }
        .alert("Invalid Page", isPresented: $showValidationError) {
            Button("OK", role: .cancel) {
                viewModel.lastPageRead = ""
                viewModel.isShowingAlertValue = true
            }
        } message: {
            Text(validationMessage)
        }
        .navigationDestination(isPresented: $viewModel.isShowingSummary) {
            SessionSummary(
                readingTime: viewModel.timeElapsed,
                currentBook: selectedBook,
                pagesRead: Int(viewModel.lastPageRead) ?? selectedBook.progress ?? 0,
                previousProgress: viewModel.previousProgress,
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
        .frame(width: 120, height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
    }
}
