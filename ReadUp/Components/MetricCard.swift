import SwiftUI

struct MetricCard: View {
    let value: String
    let title: String
    let icon: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.iconInline)
                .foregroundStyle(accentColor)
                .padding(10)
            
            Text(value)
                .font(.displayMetric)
                .foregroundStyle(accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.inkMuted)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardSurface(radius: Radius.xl)
    }
}
