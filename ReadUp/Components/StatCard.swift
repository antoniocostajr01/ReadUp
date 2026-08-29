import SwiftUI

struct StatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: icon)
                .font(.bodySupporting)
                .foregroundStyle(.inkMuted)

            Text(value)
                .font(.titlePrimary)
                .foregroundStyle(.brand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .cardSurface(radius: Radius.lg)
    }
}
