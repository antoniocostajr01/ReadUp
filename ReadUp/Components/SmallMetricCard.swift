import SwiftUI

struct SmallMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.captionStrong)
                .foregroundStyle(.inkMuted)
                .tracking(1)
            Text(value)
                .font(.titleSecondary)
                .foregroundStyle(.brand)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.cardInset)
        .cardSurface(radius: Radius.md)
    }
}
