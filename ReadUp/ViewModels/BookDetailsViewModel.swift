import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class BookDetailsViewModel {
    var isShowingStatusDialog = false
    var isShowingDeleteAlert = false
    
    func deleteBook(_ book: Book, context: ModelContext) throws {
        let bookIdToDelete = book.id
        let predicate = #Predicate<LiterarySession> { session in
            session.book.id == bookIdToDelete
        }
        
        let descriptor = FetchDescriptor<LiterarySession>(predicate: predicate)
        
        let sessionsToDelete = try context.fetch(descriptor)
        
        for session in sessionsToDelete {
            context.delete(session)
        }
        
        context.delete(book)
        try context.save()
    }
}
