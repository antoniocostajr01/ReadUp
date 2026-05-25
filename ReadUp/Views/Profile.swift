import SwiftUI

struct Profile: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(.emphasis)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

                    VStack(spacing: 4) {
                        Text("Alexandre Silva")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.mainText)

                        Text("Avid reader, aspiring philosopher, and collector\nof rare sci-fi prints. Member since 2022.")
                            .font(.subheadline)
                            .foregroundStyle(.secundaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 16)

                // Stats
                HStack(spacing: 0) {
                    StatItem(value: "24", title: "Books Read")
                    Divider()
                        .frame(height: 40)
                    StatItem(value: "8,420", title: "Total Pages")
                    Divider()
                        .frame(height: 40)
                    StatItem(value: "12", title: "Day Streak")
                }
                .padding(.vertical, 16)
                .background(.componentBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)

                // Preferences
                VStack(alignment: .leading, spacing: 12) {
                    Text("PREFERENCES")
                        .font(.caption)
                        .foregroundStyle(.secundaryLabel)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        PreferenceRow(icon: "person.fill", title: "Account Settings", iconColor: .blue)
                        Divider().padding(.leading, 56)
                        PreferenceRow(icon: "flag.fill", title: "Reading Goals", iconColor: .indigo)
                        Divider().padding(.leading, 56)
                        PreferenceRow(icon: "bell.fill", title: "Notifications", iconColor: .red)
                        Divider().padding(.leading, 56)
                        PreferenceRow(icon: "circle.circle.fill", title: "Help & Support", iconColor: .gray)
                    }
                    .background(.componentBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal)

                // Sign Out
                Button(action: {}) {
                    Text("Sign Out")
                        .font(.body)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.componentBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(.backgroundPrimary)
        .navigationTitle("Profile")
    }
}

// Subviews
struct StatItem: View {
    var value: String
    var title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.mainText)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secundaryLabel)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementItem: View {
    var icon: String
    var title: String
    var color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(title == "Locked" ? .secundaryLabel : .mainText)
        }
    }
}

struct PreferenceRow: View {
    var icon: String
    var title: String
    var iconColor: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.body)
                .foregroundStyle(.mainText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.secundaryLabel)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.componentBackground)
    }
}

#Preview {
    NavigationStack {
        Profile()
    }
}
