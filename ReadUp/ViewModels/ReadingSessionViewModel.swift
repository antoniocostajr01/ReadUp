import Foundation
import SwiftUI

@MainActor
@Observable
final class ReadingSessionViewModel {
    var timeElapsed = 0
    var isShowingSummary = false
    var isShowingAlertValue = false
    var lastPageRead = ""
    var countdown = 5
    var isSessionRunning = false
    var previousProgress = 0

    private static let countdownDuration: TimeInterval = 5

    // Âncora: fim do countdown == início da sessão. Todo o estado do timer é
    // derivado de Date.now - âncora, então o tempo segue contando mesmo com o
    // app suspenso (tela bloqueada/background).
    private(set) var sessionStartDate: Date?
    private var uiTimer: Timer?

    // Idempotente: não reseta a âncora se a sessão já começou (ex.: voltar do summary).
    func start() {
        if sessionStartDate == nil {
            sessionStartDate = Date.now.addingTimeInterval(Self.countdownDuration)
        }
        refresh()
        startUITimer()
    }

    func refresh(now: Date = .now) {
        guard let start = sessionStartDate else { return }
        let delta = now.timeIntervalSince(start)
        if delta < 0 {
            countdown = max(1, Int((-delta).rounded(.up)))
        } else {
            if !isSessionRunning { isSessionRunning = true }
            timeElapsed = Int(delta)
        }
    }

    private func startUITimer() {
        uiTimer?.invalidate()
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stopAllTimers() {
        uiTimer?.invalidate()
        uiTimer = nil
    }

    func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainderSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainderSeconds)
    }
}
