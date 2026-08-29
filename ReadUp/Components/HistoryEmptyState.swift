//
//  HistoryEmptyState.swift
//  ReadUp
//
//  Created by Antonio Costa on 10/10/25.
//

import SwiftUI

struct HistoryEmptyState: View {
    
    
    var body: some View {
        VStack(spacing: Spacing.cardInset) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color.inkMuted)

            Text(Localization.History.emptyTitle.string)
                .font(.titleTertiary)
                .foregroundStyle(Color.ink)

            Text(Localization.History.emptySubtitle.string)
                .font(.bodySupporting)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 18)
        .cardSurface(radius: Radius.xl)
    }
}

#Preview {
    HistoryEmptyState()
}
