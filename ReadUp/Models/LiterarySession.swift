//
//  LiterarySession.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import Foundation
import SwiftData

@Model
final class LiterarySession: Identifiable{
    var id = UUID()
    var book: Book
    var pagesRead: Int
    var timeRead: Int
    var thoughts: String
    var timesTamp: Date
    
    init(book: Book, pagesRead: Int, progress: Int, timeRead: Int, thoughts: String) {
        self.book = book
        self.pagesRead = pagesRead
        self.timeRead = timeRead
        self.thoughts = thoughts
        self.timesTamp = Date()
    }
}
