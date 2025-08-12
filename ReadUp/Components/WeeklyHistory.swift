//
//  WeeklyHistory.swift
//  ReadUp
//
//  Created by Antonio Costa on 07/08/25.
//

import SwiftUI

struct WeeklyHistory: View {
    
    var weekDay: String
    var bookRead: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: bookRead == false ? "book.closed.fill" : "book.fill")
                .foregroundStyle(bookRead == false ? .componentBackground : .green)
            Text(weekDay)
                .foregroundStyle(bookRead == false ? .componentBackground : .green)
                .font(.headline)
        }
        .frame(width: 44, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(bookRead == false ? .secundaryLabel : .weekDayBackground )
            )
    }
}

#Preview {
    WeeklyHistory(weekDay: "M", bookRead: false)
}
