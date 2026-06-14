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
    
    private var timer: Timer?
    private var countdownTimer: Timer?
    
    func startCountdown() {
        stopAllTimers()
        countdown = 5
        isSessionRunning = false

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else { return }
                if self.countdown > 1 {
                    self.countdown -= 1
                } else {
                    timer.invalidate()
                    self.countdownTimer = nil
                    self.isSessionRunning = true
                    self.startSessionTimer()
                }
            }
        }
    }

    func startSessionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timeElapsed += 1
            }
        }
    }

    func stopAllTimers() {
        timer?.invalidate()
        countdownTimer?.invalidate()
        timer = nil
        countdownTimer = nil
    }

    func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainderSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainderSeconds)
    }
}
