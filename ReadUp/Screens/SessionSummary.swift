//
//  SessionSummary.swift
//  ReadUp
//
//  Created by Antonio Costa on 09/08/25.
//

import SwiftUI
import SwiftData
import Foundation

struct SessionSummary: View {
    
    @Environment(\.modelContext)var modelContextSessions
    
    @Environment(\.dismiss)var dismiss
    
    @Query var sessions: [LiterarySession]
    @Query var books: [Book]
    
    @State var readingTime: Int
    
    @State var navigateToSessionsHistory: Bool = false
    
    @State var wasSavedSession: Bool = false
    
    @State var currentBook: Book
    
    @State var pagesRead: Int
    
    @State var thoughts: String = ""
    
    @Binding var dismissModal: Bool //CONTROLA MODAL, NAAAAOOO MEXER
    
    @State var sessionToEdit: LiterarySession?
    
    private func setupForEditting(){
        if let session = sessionToEdit {
            self.pagesRead = session.pagesRead
            self.currentBook = session.book
            self.thoughts = session.thoughts
            self.readingTime = session.timeRead
        }
    }
    
    var body: some View {
        ScrollView{
            Text("Reading Session Summary")
                .font(.system(.title2, weight: .semibold))
            
            HStack(alignment: .center, spacing: 55){
                TitleAndAuthorBook(bookAuthor: currentBook.author, bookTitle: currentBook.title)
                
                if let bookCover = UIImage(data: currentBook.imageData){
                    Image(uiImage: bookCover)
                        .resizable()
                        .frame(width: 100, height: 143)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 16)
            
            
            Text("Page progress")
                .font(.system(.title3, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
            
            HStack(spacing: 48){
                VStack{
                    Text("\(currentBook.progress!)/\(currentBook.numberOfPages)")
                    Text(timeString(from: readingTime))
                }
                
                VStack(spacing: 16){
                    Text("You already read")
                        .font(.system(.title3, weight: .regular))
                        .foregroundStyle(.secundaryLabel)
                    VStack{
                        var percentage: Int {
                            let pagesRead = Double(currentBook.progress!)
                            let totalPages = Double(currentBook.numberOfPages)
                            guard totalPages > 0 else { return 0 }
                            let progressPercentage = (pagesRead / totalPages) * 100
                            return Int(progressPercentage.rounded())
                        }
                        Text("\(percentage)%")
                            .font(.system(.largeTitle, weight: .bold))
                            .padding(.top, 29)
                            .padding(.bottom, 29)
                            .padding(.leading, 13)
                            .padding(.trailing, 13)
                        
                    }
                    .frame(width: 120, height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 60)
                            .stroke(.emphasis, lineWidth: 13)
                            .foregroundStyle(.componentBackground)
                    )
                    
                    Text("of the book")
                        .font(.system(.title3, weight: .regular))
                        .foregroundStyle(.secundaryLabel)
                    
                }
            }
            
            Text("Write your thoughts (opcional)")
                .font(.system(.title3, weight: .semibold))
                .padding(.top, 30)
            
            TextField("More details about the task", text: $thoughts, axis: .vertical)
                .lineLimit(5...10)
                .padding(.vertical, 12)
                .padding(.leading, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.componentBackground)
                )
            
        
            Button(action:{
        
                saveSession()
                navigateToSessionsHistory.toggle()
                dismissModal = false
                
            }) {
                Text("Save Session")
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(.componentBackground)
                    .frame(width: 361, height: 61)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .foregroundStyle(.emphasis)
                    )
            }
            .padding(.top, 24)
        }
        .padding()
        .background(.backgroundPrimary)
        .onAppear(perform: setupForEditting)
    }
        
    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func saveSession() {
        let session = LiterarySession(book: currentBook, pagesRead: pagesRead, progress: pagesRead, timeRead: readingTime, thoughts: thoughts)
        modelContextSessions.insert(session)
        
        print(session.book.title, session.timeRead, session.id, session.pagesRead)
        
        do{
            try modelContextSessions.save()
            
            wasSavedSession = true
            
            dismissModal = false //COMPORTAMENTO DA MODAL, NÃO MEXER
            

        } catch {
            print("Failed to save session")
        }
    }
}

//
//
//#Preview {
//    let bookTest = Book(title: "Book Teste", author: "Eu", numberOfPages: 245, details: "CIWEMMWFWEKFOW", status: .reading)
//    SessionSummary(readingTime: 659, currentBook: bookTest)
//}
