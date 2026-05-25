import SwiftUI

struct MetricCard: View {
    let value: String
    let title: String
    let icon: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(accentColor)
                .padding(10)
            
            Text(value)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secundaryLabel)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
