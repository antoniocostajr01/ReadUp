import ActivityKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class ReadingSessionViewModel {
    var timeElapsed = 0
    var isShowingAlertValue = false
    var lastPageRead = ""
    var countdown = 5
    var isSessionRunning = false
    var previousProgress = 0
    var isSaving = false
    /// A sessão gravada ao confirmar a página — sua presença é o que empurra o
    /// `SessionSummary` na tela.
    var savedSession: LiterarySession?

    private static let countdownDuration: TimeInterval = 5

    // Âncora: fim do countdown == início da sessão. Todo o estado do timer é
    // derivado de Date.now - âncora, então o tempo segue contando mesmo com o
    // app suspenso (tela bloqueada/background).
    private(set) var sessionStartDate: Date?
    private var uiTimer: Timer?
    private var activity: Activity<ReadingSessionAttributes>?
    private var isStartingActivity = false
    /// Fecha a corrida com um `Activity.request` em voo: sem isto, sair durante o
    /// `stageCover` assíncrono deixaria o request terminar depois e ressuscitar um
    /// card que o `endLiveActivity` já achava ter encerrado.
    private var isEnded = false

    // Idempotente: não reseta a âncora se a sessão já começou (ex.: voltar do summary).
    func start(book: Book) {
        if sessionStartDate == nil {
            sessionStartDate = Date.now.addingTimeInterval(Self.countdownDuration)
        }
        refresh()
        startUITimer()
        startLiveActivity(for: book)
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

    // MARK: Live Activity

    /// Também idempotente: `start(book:)` roda de novo ao voltar do summary, e uma
    /// segunda `request` criaria um card duplicado no lock screen. A flag existe
    /// porque a preparação da capa é assíncrona — sem ela, duas chamadas passariam
    /// pelo `activity == nil` antes de qualquer uma ter atribuído a atividade.
    private func startLiveActivity(for book: Book) {
        guard activity == nil, !isStartingActivity,
              let start = sessionStartDate,
              ActivityAuthorizationInfo().areActivitiesEnabled
        else { return }

        isStartingActivity = true
        Task {
            // A capa tem que estar no disco compartilhado *antes* do request: o card
            // é desenhado uma vez, quando a atividade nasce, e a extensão não tem
            // como buscar a imagem depois.
            await stageCover(for: book)
            guard !isEnded else { return }

            let content = ActivityContent(
                state: ReadingSessionAttributes.ContentState(),
                staleDate: start.addingTimeInterval(ReadingSessionAttributes.maxDuration)
            )

            // Sem update e sem push: o card desenha o cronômetro a partir de `startDate`.
            activity = try? Activity.request(
                attributes: ReadingSessionAttributes(
                    bookTitle: book.title,
                    bookAuthor: book.author,
                    startDate: start
                ),
                content: content,
                pushType: nil
            )
            isStartingActivity = false
        }
    }

    /// Normalmente instantâneo: a capa já passou pelo `CoverImageCache` no Home e na
    /// própria tela de sessão. Sem capa, limpa o arquivo — senão a sessão de hoje
    /// herdaria a capa da sessão anterior.
    private func stageCover(for book: Book) async {
        guard let raw = book.coverUrl,
              let url = URL(string: raw),
              let image = await CoverImageCache.load(url)
        else {
            SharedCoverStore.clear()
            return
        }
        SharedCoverStore.write(image)
    }

    /// Não confia mais no próprio handle: encerra *toda* atividade do tipo, não só a
    /// que este view model acha que criou. Root-cause fix para três vazamentos — handle
    /// escopado à view destruída, `isStartingActivity` ignorado ao sair, e crash/force
    /// quit que só o `staleDate` de 8h resolveria sozinho.
    func endLiveActivity() {
        SharedCoverStore.clear()
        isEnded = true // fecha a corrida com o request em voo
        activity = nil
        Task {
            for activity in Activity<ReadingSessionAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// Roda uma vez no launch do app: limpa qualquer card que tenha sobrevivido a um
    /// crash ou force-quit, já que nesse caso nenhum `endLiveActivity()` de instância
    /// chega a rodar.
    static func endAllReadingActivities() {
        Task {
            for activity in Activity<ReadingSessionAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainderSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainderSeconds)
    }
}
