import SwiftUI

struct Profile: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(.emphasis)

            Text("Profile")
                .font(.system(.title2, weight: .bold))

            Text("Your profile settings will live here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secundaryLabel)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundPrimary)
        .navigationTitle("Profile")
    }
}

#Preview {
    Profile()
}
