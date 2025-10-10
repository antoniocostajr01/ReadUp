//
//  HistoryEmptyState.swift
//  ReadUp
//
//  Created by Antonio Costa on 10/10/25.
//

import SwiftUI

struct HistoryEmptyState: View {
    
    
    var body: some View {
        VStack(alignment: .center, spacing: 32){
            
            Image(.sadMascot)
            VStack(alignment: .center, spacing: 8){
                Text("No reading sessions yet")
                    .font(Font.title.bold())
                
                Text("Choose a book you’re reading and start your first session to see your growth.")
                    .multilineTextAlignment(.center)
                
            }
        }
    }
}

#Preview {
    HistoryEmptyState()
}
