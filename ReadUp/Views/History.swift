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
        .navigationTitle(Localization.History.title.string)
        .navigationDestination(item: $selectedSession) { session in
            SessionSummary(readingTime: session.timeRead, currentBook: session.book, pagesRead: session.pagesRead, previousProgress: max(0, session.pagesRead - session.pagesRead), sessionToEdit: session)
        }
        
    }
}

#Preview {
    History()
}
