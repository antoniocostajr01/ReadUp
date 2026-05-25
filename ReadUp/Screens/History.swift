//
//  SessionsHistory.swift
//  ReadUp
//
//  Created by Antonio Costa on 09/08/25.
//

import SwiftUI
import SwiftData

struct History: View {
    
    @Query(sort: \LiterarySession.timesTamp, order: .reverse) var sessions: [LiterarySession]
    
    @State private var selectedSession: LiterarySession?
    
    @State private var isShowModal: Bool = false
    
    var body: some View {
        VStack{
            if sessions.isEmpty {
                HistoryEmptyState()
            } else {
                ScrollView{
                    ForEach(sessions) { session in
                        SessionDetails(session: session)
                            .onTapGesture {
                                selectedSession = session
                            }
                    }
                }
            }
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundPrimary)
        .navigationTitle("History")
        .sheet(item: $selectedSession ){ session in
            NavigationStack{
                SessionSummary(readingTime: session.timeRead, currentBook: session.book, pagesRead: session.pagesRead, sessionToEdit: session )
                    .presentationDragIndicator(.visible)
                
            }
        }
        
    }
}

#Preview {
    History()
}
