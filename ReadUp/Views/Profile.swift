import SwiftUI

struct Profile: View {
    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "person.crop.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secundaryLabel)

            Text("Coming soon")
                .font(.title3)
                .foregroundStyle(.secundaryLabel)
                .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(.backgroundPrimary)
        .navigationTitle("Profile")
    }
}

#Preview {
    NavigationStack {
        Profile()
    }
}
