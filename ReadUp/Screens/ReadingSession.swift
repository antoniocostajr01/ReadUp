//
//  ReadingSession.swift
//  ReadUp
//
//  Created by Antonio Costa on 07/08/25.
//
import SwiftData
import SwiftUI

struct ReadingSession: View {
    
    @State private var timeElapsed = 0
    
    @State private var formattedTime = ""
    
    @State private var isShowingSummary = false
    
    @State private var isShowingAlertValue = false
    
    @State private var lastPageRead = ""
    
    @State private var isShowingCancelAlert = false
    
    @Binding var dismissModal: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var selectedBook: Book
        
    var body: some View {

        NavigationStack{
            VStack{
                
                if let bookCover = UIImage(data: selectedBook.imageData){
                    Image(uiImage: bookCover)
                        .resizable()
                        .frame(width: 191, height: 272)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                TitleAndAuthorBook(bookAuthor: selectedBook.author, bookTitle: selectedBook.title)
                
                StopWatchView(timeElapsed: $timeElapsed)
    
                Button{
                    isShowingAlertValue.toggle()
                    
                } label: {
                    Text("Finish session")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.componentBackground)
                        .frame(width: 361, height: 61)
                        .background(
                            RoundedRectangle(cornerRadius: 50)
                                .foregroundStyle(.emphasis)
                        )
                }
                .padding(.horizontal)
                
                
                .alert("Which page did you leave off?", isPresented: $isShowingAlertValue){
                    TextField("Page", text: $lastPageRead)
                        .keyboardType(.numberPad)
                    
                    Button("Confirm"){
                        if let pageConvertedToInt = Int(lastPageRead){
                            
                            print("Pagina lida: \(pageConvertedToInt)")
                            selectedBook.progress = pageConvertedToInt
                            isShowingSummary.toggle()
                            
                            
                        }
                    }
                    
                    Button("Cancel", role: .cancel){
                        lastPageRead = ""
                    }
                }
            }
            .padding(.vertical)
            .navigationDestination(isPresented: $isShowingSummary) {
                SessionSummary(
                    readingTime: timeElapsed,
                    currentBook: selectedBook,
                    pagesRead: Int(lastPageRead) ?? selectedBook.progress ?? 0,
                    thoughts: "",
                    dismissModal: $dismissModal //CONTROLA O MODAL NAO MEXER
                )
            }
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingCancelAlert.toggle()
                    } label: {
                        Text("Cancel")
                            .imageScale(.large)
                    }
                }
            }
            .alert("Are you sure you want to exit the session?", isPresented: $isShowingCancelAlert) {
                Button("Exit", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your reading progress will not be saved.")
            }
        }
    }
}
