//
//  HistoryEmptyState.swift
//  ReadUp
//
//  Created by Antonio Costa on 10/10/25.
//

import SwiftUI

struct HistoryEmptyState: View {
    
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color(uiColor: .secondaryLabel))

            Text(Localization.History.emptyTitle.string)
                .font(.system(.title3, weight: .semibold))
                .foregroundStyle(Color(uiColor: .label))

            Text(Localization.History.emptySubtitle.string)
                .font(.subheadline)
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

#Preview {
    HistoryEmptyState()
}
