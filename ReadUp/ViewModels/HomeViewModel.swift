import Foundation

@Observable
final class HomeViewModel {
    let mockUserName = "Antonio"
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        if hour < 12 {
            greeting = Localization.Home.greetingMorning.string
        } else if hour < 18 {
            greeting = Localization.Home.greetingAfternoon.string
        } else {
            greeting = Localization.Home.greetingEvening.string
        }
        return "\(greeting), \(mockUserName)"
    }
    
    func averageMinutesPerDay(from sessions: [LiterarySession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let totalMinutes = sessions.reduce(0) { $0 + ($1.timeRead / 60) }
        return totalMinutes / sessions.count
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
}
