import SwiftUI

struct ReadingSession: View {
    let selectedBook: Book
    @Binding var activeReadingBook: Book?

    @State private var viewModel = ReadingSessionViewModel()
    @State private var showValidationError = false
    @State private var validationMessage = ""
    @State private var showExitConfirmation = false
    @State private var lockAnimationTrigger = false
    @State private var isPhoneLocked = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            coverView

            VStack(spacing: 4) {

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

            sessionCard

            Spacer()

            Button {
                viewModel.isShowingAlertValue = true
            } label: {
                Label(Localization.ReadingSession.finish.string, systemImage: "checkmark.circle")
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
        .navigationTitle(Localization.ReadingSession.title.string)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showExitConfirmation = true
                } label: {
                    Text(Localization.ReadingSession.leave.string)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.startCountdown()
        }
        .onDisappear {
            viewModel.stopAllTimers()
        }
        .alert(Localization.ReadingSession.pagePrompt.string, isPresented: $viewModel.isShowingAlertValue) {
            TextField(Localization.ReadingSession.pagePlaceholder.string, text: $viewModel.lastPageRead)
                .keyboardType(.numberPad)

            Button(Localization.Generic.confirm.string) {
                if let page = Int(viewModel.lastPageRead) {
                    let currentProgress = selectedBook.progress ?? 0

                    if page < currentProgress {
                        validationMessage = String(format: Localization.ReadingSession.cantGoBack.string, currentProgress)
                        showValidationError = true
                        return
                    }

                    if page > selectedBook.numberOfPages {
                        validationMessage = String(format: Localization.ReadingSession.exceedsPages.string, selectedBook.numberOfPages)
                        showValidationError = true
                        return
                    }

                    // Salva progresso anterior antes de atualizar
                    viewModel.previousProgress = currentProgress
                    selectedBook.progress = page
                    viewModel.isShowingSummary = true
                }
            }

            Button(Localization.Generic.cancel.string, role: .cancel) {
                viewModel.lastPageRead = ""
            }
        }
        .alert(Localization.ReadingSession.invalidPage.string, isPresented: $showValidationError) {
            Button(Localization.Generic.ok.string, role: .cancel) {
                viewModel.lastPageRead = ""
                viewModel.isShowingAlertValue = true
            }
        } message: {
            Text(validationMessage)
        }
        .alert(Localization.ReadingSession.leaveTitle.string, isPresented: $showExitConfirmation) {
            Button(Localization.ReadingSession.leave.string, role: .destructive) {
                viewModel.stopAllTimers()
                dismiss()
            }
            Button(Localization.ReadingSession.stay.string, role: .cancel) {}
        } message: {
            Text(Localization.ReadingSession.leaveMessage.string)
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

    private var sessionCard: some View {
        ZStack {
            // Estado: sessão rodando (timer + current page)
            VStack(spacing: 14) {
                Text(viewModel.timeString(from: viewModel.timeElapsed))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()

                SmallMetricCard(title: Localization.ReadingSession.currentPage.string, value: "\(selectedBook.progress ?? 0)")
            }
            .opacity(viewModel.isSessionRunning ? 1 : 0)

            // Estado: countdown (número + lock tip)
            VStack(spacing: 14) {
                Text("\(viewModel.countdown)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.emphasis)

                Image(systemName: isPhoneLocked ? "lock.iphone" : "lock.open.iphone")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.emphasis)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, options: .nonRepeating, value: lockAnimationTrigger)

                Text(Localization.ReadingSession.lockTip.string)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(Localization.ReadingSession.lockSubtip.string)
                    .font(.body)
                    .foregroundStyle(.secundaryLabel)
            }
            .opacity(viewModel.isSessionRunning ? 0 : 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.4), value: viewModel.isSessionRunning)
        .onAppear {
            lockAnimationTrigger = true
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                while !viewModel.isSessionRunning {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isPhoneLocked.toggle()
                    }
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                }
            }
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
