//
//  SessionsHistory.swift
//  ReadUp
//
//  Created by Antonio Costa on 09/08/25.
//

import SwiftUI
import SwiftData

struct SessionsHistory: View {
    
    @Query(sort: \LiterarySession.timesTamp, order: .reverse) var sessions: [LiterarySession]

    @State private var selectedSession: LiterarySession?
    
    @State private var isShowModal: Bool = false // MODAL NAO MEXER
    
    var body: some View {
        ScrollView(){
                
            VStack{
                ForEach(sessions) { session in
                    
                    SessionDetails(session: session)
                        .onTapGesture {
                            selectedSession = session
                        }
                }
            }
            
        } //Final da scrollView
        .padding()
        .navigationTitle("Sessions History")
        .background(.backgroundPrimary)
        .sheet(item: $selectedSession ){ session in
            NavigationStack{
                SessionSummary(readingTime: session.timeRead, currentBook: session.book, pagesRead: session.pagesRead, dismissModal: .constant(false), sessionToEdit: session )
            }
        }
    }
}
//
//#Preview {
//    SessionsHistory()
//}
