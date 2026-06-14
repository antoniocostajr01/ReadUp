import SwiftUI

struct Profile: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showSignOutConfirmation = false

    private var displayName: String {
        authManager.currentUser?.name ?? "Reader"
    }

    private var email: String {
        authManager.currentUser?.email ?? ""
    }

    private var chosenGenres: [Genre] {
        GenreCatalog.genres(for: authManager.genres)
    }

    private var availableToAdd: [Genre] {
        GenreCatalog.all.filter { !authManager.genres.contains($0.title) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Cabeçalho do usuário
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 84))
                        .foregroundStyle(.emphasis)

                    Text(displayName)
                        .font(.title2.weight(.bold))

                    if !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secundaryLabel)
                    }
                }
                .padding(.top, 16)

                genresSection

                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Text("Sign Out")
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(.backgroundPrimary)
        .navigationTitle("Profile")
        .confirmationDialog("Sign out of ReadUp?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your genres")
                    .font(.system(.title3, weight: .bold))
                Spacer()
                if !availableToAdd.isEmpty {
                    Menu {
                        ForEach(availableToAdd) { genre in
                            Button {
                                add(genre)
                            } label: {
                                Label(genre.title, systemImage: genre.icon)
                            }
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.emphasis)
                    }
                    .disabled(authManager.isLoading)
                }
            }

            if chosenGenres.isEmpty {
                Text("No genres yet. Add some to personalize your recommendations.")
                    .font(.subheadline)
                    .foregroundStyle(.secundaryLabel)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 120), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(chosenGenres) { genre in
                        chip(for: genre)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func chip(for genre: Genre) -> some View {
        HStack(spacing: 6) {
            Image(systemName: genre.icon)
                .font(.caption)
            Text(genre.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Button {
                remove(genre)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secundaryLabel)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .foregroundStyle(.emphasis)
        .background(
            Capsule().fill(Color.emphasis.opacity(0.14))
        )
    }

    // MARK: - Ações

    private func add(_ genre: Genre) {
        let updated = authManager.genres + [genre.title]
        Task { await authManager.updateGenres(updated) }
    }

    private func remove(_ genre: Genre) {
        let updated = authManager.genres.filter { $0 != genre.title }
        Task { await authManager.updateGenres(updated) }
    }
}

#Preview {
    NavigationStack {
        Profile()
            .environment(AuthManager())
    }
}
