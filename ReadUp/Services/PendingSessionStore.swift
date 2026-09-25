//
//  PendingSessionStore.swift
//  ReadUp
//

import Foundation

/// Snapshot de uma sessão que falhou ao salvar (sem rede) — o suficiente para
/// reconstruir o mesmo POST /sessions + PUT /books/:id quando a rede voltar.
struct PendingSession: Codable, Identifiable {
    let localID: String        // o id "pending:<uuid>" usado localmente
    let bookID: String
    let pagesRead: Int         // páginas lidas NESTA sessão
    let totalProgress: Int     // progresso total do livro após a sessão
    let readingTimeSeconds: Int
    var thoughts: String
    let date: Date             // quando a sessão de fato aconteceu

    var id: String { localID }
}

/// Outbox mínimo para sessões de leitura que não conseguiram ser salvas por
/// falta de rede. É só um punhado de linhas que vivem minutos — nada de
/// SwiftData/Core Data, só um array em UserDefaults.
final class PendingSessionStore {
    static let shared = PendingSessionStore()

    private let defaultsKey = "pendingSessions"
    private let defaults = UserDefaults.standard

    private init() {}

    func all() -> [PendingSession] {
        guard let data = defaults.data(forKey: defaultsKey) else { return [] }
        return (try? JSONDecoder().decode([PendingSession].self, from: data)) ?? []
    }

    func enqueue(_ session: PendingSession) {
        var current = all()
        current.append(session)
        save(current)
    }

    func updateThoughts(localID: String, _ thoughts: String) {
        var current = all()
        guard let index = current.firstIndex(where: { $0.localID == localID }) else { return }
        current[index].thoughts = thoughts
        save(current)
    }

    func remove(localID: String) {
        save(all().filter { $0.localID != localID })
    }

    private func save(_ sessions: [PendingSession]) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    /// Reenvia cada sessão pendente, na ordem em que entrou, pelo mesmo par de
    /// chamadas que o caminho "ao vivo" do `logSession` faz. Uma entrada sai da fila
    /// quando o POST da sessão passa; o que falhar antes disso fica para a próxima
    /// tentativa.
    @MainActor
    func flush(store: LibraryStore) async {
        guard let token = KeychainHelper.read(KeychainKey.authToken) else { return }
        let sessionService = ReadingSessionService()
        let bookService = BookService()
        let dateFormatter = ISO8601DateFormatter()

        for pending in all() {
            do {
                let sessionPayload = CreateSessionPayload(
                    bookId: pending.bookID,
                    pagesRead: pending.pagesRead,
                    thoughts: pending.thoughts.isEmpty ? nil : pending.thoughts,
                    readingTimeSeconds: pending.readingTimeSeconds,
                    date: dateFormatter.string(from: pending.date)
                )
                let dto = try await sessionService.createSession(sessionPayload, token: token)

                // Sai da fila assim que o POST passa, ANTES de mexer no livro: se o
                // PUT abaixo falhar e a sessão continuasse enfileirada, o próximo
                // flush registraria a mesma leitura duas vezes. Progresso errado se
                // conserta no próximo load; sessão duplicada não.
                remove(localID: pending.localID)

                // Troca o id "pending:" pelo real na mesma hora, e não depois do PUT:
                // se ficasse para o fim, um PUT que falha deixaria a tela com um id
                // "pending:" que já não tem entrada na fila — e a próxima edição de
                // pensamentos iria para lugar nenhum.
                if let index = store.sessions.firstIndex(where: { $0.id == pending.localID }) {
                    store.sessions[index].id = dto.id
                }

                guard let book = store.books.first(where: { $0.id == pending.bookID }) else {
                    // Livro sumiu da biblioteca local (ex.: apagado) — nada a sincronizar.
                    continue
                }
                let completed = pending.totalProgress >= book.numberOfPages
                let updatePayload = UpdateBookPayload(
                    status: BookStatus.afterSession(from: book.status, completed: completed)?.rawValue,
                    progress: pending.totalProgress
                )
                let updatedBook = try await bookService.updateBook(id: pending.bookID, updatePayload, token: token)
                store.apply(updated: updatedBook)
            } catch {
                // Ainda sem rede (ou outra falha) — mantém na fila e tenta a próxima.
                continue
            }
        }
    }
}
