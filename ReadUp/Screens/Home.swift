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
        
    @State private var isShowingModalSession = false // CONTROLA O COMPORTAMENTO DAS MODAIS, NÃO MEXER
    
    @Query var books: [Book]
    
    @Query(sort: \LiterarySession.timesTamp, order: .reverse) var sessions: [LiterarySession]
    
    var sessionsCount: Int {
        sessions.count
    }
    
    private var readingBooks: [Book]{
        books.filter {
            $0.status == .reading
        }
    }
    
    var body: some View {
            VStack{
                VStack (alignment: .center, spacing: 8){
                    Text("Literary Sessions until now:")
                        .font(.subheadline)
                    
                    
                    HStack{
                        Image(systemName: "book.fill")
                            .font(.system(size: 64, weight: .regular))
                            .foregroundStyle(.emphasis)

                        
                        Text("\(sessionsCount)")
                            .font(.system(size: 64, weight: .regular))
                            
            
                    }
                }
                .padding()
                
                
                HStack(alignment: .center, spacing: 32 ){
                    
                    VStack(alignment: .center, spacing: 16){
                        Text("“When you want something, all the universe conspires in helping you to achieve it.”")
                            .multilineTextAlignment(.center)
                            .font(.body.italic())
                        
                        Text("Paulo Coelho, The Alchemist")
                            .font(.caption.italic())
                            .foregroundStyle(.secundaryLabel)
                    }
                    .padding()
                    
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
                
                Spacer()
                
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
                .padding(.vertical, 32)
                
                
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

#Preview {
    TabBar()
}
