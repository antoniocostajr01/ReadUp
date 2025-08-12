//
//  Home.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI
import SwiftData

struct Home: View {
    
    @State var startReading: Bool = false
    
    @State private var isShowingActionSheet = false
    
    @State private var backgroundColor = Color.white
    
    @State private var selectedBook: Book?
    
    @State private var isGointToHistory = false
    
    @State private var isShowingAlert = false
        
    @State private var isShowingModalSession = false// CONTROLA O COMPORTAMENTO DAS MODAIS, NÃO MEXER
    
    @Query var books: [Book]
    
    private var readingBooks: [Book]{
        books.filter {
            $0.status == .reading
        }
    }
    
    var body: some View {
        NavigationStack{
            ScrollView{
                Button {
                    if readingBooks.isEmpty{
                        isShowingAlert.toggle()
                    } else {
                        isShowingActionSheet = true
                    }
                                        
                } label: {
                    Text("Start Reading")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.componentBackground)
                        .frame(width: 361, height: 61)
                        .background(
                            RoundedRectangle(cornerRadius: 50)
                                .foregroundStyle(.emphasis)
                        )
                }
                .alert("No Books Found" ,isPresented: $isShowingAlert) {
                    Button("Ok") {}
                } message: {
                    Text("You aren't reading any book. Please add some book with 'Reading' status to your library.")
                }
                .confirmationDialog("Select a book", isPresented: $isShowingActionSheet, titleVisibility: .visible) {

                    ForEach(readingBooks) { book in
                        Button(book.title) {
                            selectedBook = book
                            isShowingModalSession.toggle()
                        }
                    }
                }
   
                
                //MARK: Sessions History
                Button{
                    
                    isGointToHistory.toggle()
                    
                } label: {
                    HStack(spacing: 4){
                        Text("How is your progress")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.mainText)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.mainText)
                        
                        Spacer()
                    }
                }
                .padding(.top, 24)
                .navigationDestination(isPresented: $isGointToHistory) {
                    SessionsHistory()
                }
                
                HStack{
                    WeeklyHistory(weekDay: "S", bookRead: false)
                    WeeklyHistory(weekDay: "M", bookRead: true)
                    WeeklyHistory(weekDay: "T", bookRead: false)
                    WeeklyHistory(weekDay: "W", bookRead: true)
                    WeeklyHistory(weekDay: "T", bookRead: false)
                    WeeklyHistory(weekDay: "F", bookRead: true)
                    WeeklyHistory(weekDay: "S", bookRead: true)
                }
                
                Button{
                    //Go to sessions stories
                } label: {
                    HStack(spacing: 4){
                        Text("Current goal")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.mainText)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.mainText)
                        
                        Spacer()
                    }
                }
                .padding(.top, 24)
                
                
                HStack(spacing:69){
                    VStack(spacing: 32){
                        Text("Winter Book")
                            .font(.title2)
                        Text("12/25")
                            .font(.title2)
                    }
                    
                    Image(.winterMascot)
                        .resizable()
                        .frame(width:139 , height: 177)
                }
                .frame(width: 361, height: 209)
                .padding(.top, 8)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.emphasis, lineWidth: 1)
                        .foregroundStyle(.backgroundPrimary)
                )
            }
            .padding(.leading,16)
            .padding(.trailing,16)
            .navigationTitle("Home")
            .background(.backgroundPrimary)
            .sheet(isPresented: $isShowingModalSession) {
                ReadingSession(dismissModal: $isShowingModalSession, selectedBook: selectedBook!)
            }
        }

    }
    
}

#Preview {
    TabBar()
}
