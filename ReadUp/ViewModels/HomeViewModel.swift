import Foundation

@Observable
final class HomeViewModel {

    /// Saudação personalizada com o nome do usuário logado (ou só a saudação se não houver nome).
    func greetingText(name: String?) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        if hour < 12 {
            greeting = Localization.Home.greetingMorning.string
        } else if hour < 18 {
            greeting = Localization.Home.greetingAfternoon.string
        } else {
            greeting = Localization.Home.greetingEvening.string
        }
        guard let name, !name.isEmpty else { return greeting }
        return "\(greeting), \(name)"
    }
    
    /// Média diária de leitura em `mm:ss` — soma os segundos e divide pelos dias
    /// em que houve leitura (não pelo número de sessões).
    func averageTimePerDayFormatted(from sessions: [LiterarySession]) -> String {
        let days = Set(sessions.map { Calendar.current.startOfDay(for: $0.timesTamp) }).count
        guard days > 0 else { return "00:00" }
        let averageSeconds = sessions.reduce(0) { $0 + $1.timeRead } / days
        return String(format: "%02d:%02d", averageSeconds / 60, averageSeconds % 60)
    }
    
    func currentSessionStreak(from sessions: [LiterarySession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let uniqueDays = Array(Set(sessions.map { calendar.startOfDay(for: $0.timesTamp) })).sorted(by: >)
        
        guard let mostRecentDay = uniqueDays.first else { return 0 }
        let today = calendar.startOfDay(for: Date())
        
        let daysFromToday = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0
        if daysFromToday > 1 {
            return 0
        }
        
        var streak = 1
        for index in 1..<uniqueDays.count {
            let previousDay = uniqueDays[index - 1]
            let currentDay = uniqueDays[index]
            let gap = calendar.dateComponents([.day], from: currentDay, to: previousDay).day ?? 0
            
            if gap == 1 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    func progressValue(for book: Book) -> Double {
        guard book.numberOfPages > 0 else { return 0 }
        return min(1, max(0, Double(book.progress ?? 0) / Double(book.numberOfPages)))
    }
    
    func activityDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Métricas do Home

    /// Média diária em minutos inteiros. O card novo mostra "32 min", não o "32:07" do
    /// tile antigo — `averageTimePerDayFormatted` continua existindo porque o Profile
    /// ainda a usa.
    func averageMinutesPerDay(from sessions: [LiterarySession]) -> Int {
        let days = Set(sessions.map { Calendar.current.startOfDay(for: $0.timesTamp) }).count
        guard days > 0 else { return 0 }
        return sessions.reduce(0) { $0 + $1.timeRead } / days / 60
    }

    /// Páginas lidas na semana corrente.
    func pagesThisWeek(from sessions: [LiterarySession]) -> Int {
        sessionsThisWeek(from: sessions).reduce(0) { $0 + $1.pagesRead }
    }

    // MARK: - Semana

    /// O intervalo da semana corrente segundo o calendário do usuário — respeita
    /// `firstWeekday`, que não é domingo em todo lugar.
    private func currentWeek() -> DateInterval? {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())
    }

    func sessionsThisWeek(from sessions: [LiterarySession]) -> [LiterarySession] {
        guard let week = currentWeek() else { return [] }
        return sessions.filter { week.contains($0.timesTamp) }
    }

    /// Minutos lidos por dia da semana corrente, já na ordem em que as barras são
    /// desenhadas (a partir de `firstWeekday`). Sempre sete valores.
    func minutesByWeekday(from sessions: [LiterarySession]) -> [Int] {
        let calendar = Calendar.current
        var totals = [Int](repeating: 0, count: 7)
        for session in sessionsThisWeek(from: sessions) {
            // `component(.weekday:)` é 1...7 com 1 = domingo; a rotação por `firstWeekday`
            // põe o primeiro dia da semana do usuário na posição 0.
            let weekday = calendar.component(.weekday, from: session.timesTamp)
            let index = (weekday - calendar.firstWeekday + 7) % 7
            totals[index] += session.timeRead / 60
        }
        return totals
    }

    /// Os rótulos das barras, na mesma ordem — vêm do calendário, então já chegam
    /// traduzidos sem custar sete chaves de localização.
    func weekdayLabels() -> [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return (0..<7).map { symbols[($0 + offset) % 7] }
    }

    // MARK: - Métricas do History

    /// Cabeçalho do History: quantas sessões, quanto tempo, quantas páginas.
    func historyTotals(from sessions: [LiterarySession]) -> (count: Int, seconds: Int, pages: Int) {
        (
            count: sessions.count,
            seconds: sessions.reduce(0) { $0 + $1.timeRead },
            pages: sessions.reduce(0) { $0 + $1.pagesRead }
        )
    }

    /// "21h 12m" — e só "12m" quando não houve uma hora inteira.
    func durationFormatted(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    /// As sessões partidas em "esta semana" e o resto. A lista já chega ordenada do
    /// `LibraryStore`, então aqui é só um particionamento.
    func sessionsByPeriod(
        from sessions: [LiterarySession]
    ) -> (thisWeek: [LiterarySession], earlier: [LiterarySession]) {
        guard let week = currentWeek() else { return ([], sessions) }
        var thisWeek: [LiterarySession] = []
        var earlier: [LiterarySession] = []
        for session in sessions {
            if week.contains(session.timesTamp) {
                thisWeek.append(session)
            } else {
                earlier.append(session)
            }
        }
        return (thisWeek, earlier)
    }

    /// A linha de meta de uma sessão no History: "Today, 8:12 PM · 41 min".
    func sessionMeta(_ session: LiterarySession) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let minutes = max(1, session.timeRead / 60)
        return "\(formatter.string(from: session.timesTamp)) · \(minutes) min"
    }
}
