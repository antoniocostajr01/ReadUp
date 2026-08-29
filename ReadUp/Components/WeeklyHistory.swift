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
        VStack(spacing: Spacing.xs) {
            Image(systemName: bookRead == false ? "book.closed.fill" : "book.fill")
                .foregroundStyle(bookRead == false ? .inkInverse : .green)
            Text(weekDay)
                .foregroundStyle(bookRead == false ? .inkInverse : .green)
                .font(.headline)
        }
        .frame(width: 44, height: 64)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .foregroundStyle(bookRead == false ? .inkMuted : .brandSoft )
            )
    }
}

#Preview {
    WeeklyHistory(weekDay: "M", bookRead: false)
}
