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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            coverView

            VStack(spacing: Spacing.xs) {

                Text(selectedBook.title)
                    .font(.titlePrimary)
                    .multilineTextAlignment(.center)

                Text(selectedBook.author)
                    .font(.title3)
                    .italic()
                    .foregroundStyle(.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            sessionCard

            Spacer()

            Button {
                viewModel.isShowingAlertValue = true
            } label: {
                Label(Localization.ReadingSession.finish.string, systemImage: "checkmark.circle")
                    .font(.titleTertiary)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.cardInset)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                            .fill(Color.brand)
                    )
            }
            .disabled(!viewModel.isSessionRunning)
            .opacity(viewModel.isSessionRunning ? 1 : 0.5)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .background(.surface)
        .navigationTitle(Localization.ReadingSession.title.string)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showExitConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel(Localization.ReadingSession.leave.string)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stopAllTimers()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refresh()
            }
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

                    // Salva o progresso anterior; o novo progresso é persistido ao salvar a sessão.
                    viewModel.previousProgress = currentProgress
                    viewModel.lastPageRead = "\(page)"
                    viewModel.refresh()
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
            VStack(spacing: Spacing.cardInset) {
                Text(viewModel.timeString(from: viewModel.timeElapsed))
                    .font(.displayTimer)
                    .monospacedDigit()

                SmallMetricCard(title: Localization.ReadingSession.currentPage.string, value: "\(selectedBook.progress ?? 0)")
            }
            .opacity(viewModel.isSessionRunning ? 1 : 0)

            // Estado: countdown (número + lock tip)
            VStack(spacing: Spacing.cardInset) {
                Text("\(viewModel.countdown)")
                    .font(.displayTimer)
                    .foregroundStyle(.brand)

                Image(systemName: isPhoneLocked ? "lock.iphone" : "lock.open.iphone")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.brand)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, options: .nonRepeating, value: lockAnimationTrigger)

                Text(Localization.ReadingSession.lockTip.string)
                    .font(.titleTertiary)
                    .foregroundStyle(.primary)

                Text(Localization.ReadingSession.lockSubtip.string)
                    .font(.bodyDefault)
                    .foregroundStyle(.inkMuted)
            }
            .opacity(viewModel.isSessionRunning ? 0 : 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, 20)
        .cardSurface(radius: Radius.xl)
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
        BookCoverView(coverUrl: selectedBook.coverUrl, width: 120, height: 170, cornerRadius: Radius.md)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
    }
}
