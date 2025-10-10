//
//  Book.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import Foundation
import SwiftData


@Model
final class Book: Identifiable{
    var id = UUID()
    var title: String
    var author: String
    var numberOfPages: Int
    var details: String
    var status: BookStatus
    var imageData: Data
    var progress: Int?
    
    
    init(title: String, author: String, numberOfPages: Int, details: String, status: BookStatus, imageData: Data) {
        self.title = title
        self.author = author
        self.numberOfPages = numberOfPages
        self.details = details
        self.status = status
        self.imageData = imageData
    }
}
