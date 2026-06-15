//
//  SessionDetails.swift
//  ReadUp
//
//  Created by Antonio Costa on 10/08/25.
//

import SwiftUI

struct SessionDetails: View {
    let session: LiterarySession
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            
            BookCoverView(coverUrl: session.book.coverUrl, width: 62, height: 88, cornerRadius: 12)
            
            VStack{
                Text(session.book.title)
                    .lineLimit(1)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(.mainText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                
                Text(session.book.author)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.secundaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 159)
            
            VStack(spacing: 35){
                Text(timeString(from: session.timeRead))
                    .font(.system(.title3, weight: .regular))
                
                Text("\(session.pagesRead)")
            }
 
        }//Final da Hstack
        .frame(width: 361, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.emphasis, lineWidth: 1)
                .foregroundStyle(.componentBackground)
                .background(RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(.componentBackground)
                           )
        )
        
    }
    
    
    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

