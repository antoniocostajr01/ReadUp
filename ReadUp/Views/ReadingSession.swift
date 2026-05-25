import SwiftUI

struct ReadingSession: View {
    let selectedBook: Book
    @Binding var activeReadingBook: Book?

    @State private var timeElapsed = 0
    @State private var isShowingSummary = false
    @State private var isShowingAlertValue = false
    @State private var lastPageRead = ""
    @State private var countdown = 3
    @State private var isSessionRunning = false
    @State private var timer: Timer?
    @State private var countdownTimer: Timer?

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
                    smallMetricCard(title: "PAGES READ", value: "\(pagesReadInSession)")
                    smallMetricCard(title: "CURRENT PAGE", value: "\(selectedBook.progress ?? 0)")
                }

                Button {
                    isShowingAlertValue = true
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
                .disabled(!isSessionRunning)
                .opacity(isSessionRunning ? 1 : 0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(.backgroundPrimary)
        .navigationTitle("Reading Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            stopAllTimers()
        }
        .alert("Which page did you leave off?", isPresented: $isShowingAlertValue) {
            TextField("Page", text: $lastPageRead)
                .keyboardType(.numberPad)

            Button("Confirm") {
                if let page = Int(lastPageRead) {
                    selectedBook.progress = page
                    isShowingSummary = true
                }
            }

            Button("Cancel", role: .cancel) {
                lastPageRead = ""
            }
        }
        .navigationDestination(isPresented: $isShowingSummary) {
            SessionSummary(
                readingTime: timeElapsed,
                currentBook: selectedBook,
                pagesRead: Int(lastPageRead) ?? selectedBook.progress ?? 0,
                thoughts: "",
                onSessionSaved: {
                    activeReadingBook = nil
                }
            )
        }
    }

    private var pagesReadInSession: Int {
        let current = selectedBook.progress ?? 0
        let entered = Int(lastPageRead) ?? current
        return max(0, entered - current)
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
                .trim(from: 0, to: min(CGFloat(timeElapsed % 3600) / 3600, 1))
                .stroke(Color.emphasis, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(Color(uiColor: .secondarySystemBackground))
                .padding(24)

            if isSessionRunning {
                Text(timeString(from: timeElapsed))
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
            } else {
                Text("\(countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.emphasis)
            }
        }
        .frame(width: 300, height: 300)
        .padding(.top, 8)
    }

    private func smallMetricCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secundaryLabel)
                .tracking(1)
            Text(value)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(.emphasis)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func startCountdown() {
        stopAllTimers()
        countdown = 3
        isSessionRunning = false

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                countdownTimer = nil
                isSessionRunning = true
                startSessionTimer()
            }
        }
    }

    private func startSessionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }

    private func stopAllTimers() {
        timer?.invalidate()
        countdownTimer?.invalidate()
        timer = nil
        countdownTimer = nil
    }

    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
