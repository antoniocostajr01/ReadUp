import SwiftUI

struct AIMessageBubble: View {
    let message: AIChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                Text(LocalizedStringKey(message.text))
                    .font(.body)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                Text(LocalizedStringKey(message.text))
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.emphasis)
                    )
            }
        }
    }
}
