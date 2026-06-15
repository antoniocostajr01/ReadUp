//
//  LiterarySession.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import Foundation

/// Sessão de leitura já "montada" para a UI: carrega o `Book` resolvido
/// (o backend devolve só `bookId`; o `LibraryStore` faz o join).
/// `timeRead` está em segundos; `timesTamp` é a data da sessão.
struct LiterarySession: Identifiable, Hashable {
    let id: String
    var book: Book
    var pagesRead: Int
    var timeRead: Int
    var thoughts: String
    var timesTamp: Date
}
