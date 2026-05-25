import SwiftUI

struct SmallMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secundaryLabel)
                .tracking(1)
            Text(value)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(.emphasis)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
