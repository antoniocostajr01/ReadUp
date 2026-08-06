import SwiftUI
import PhotosUI

struct Profile: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showDeleteAccountError = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showEditName = false
    @State private var draftName = ""

    private var displayName: String {
        authManager.currentUser?.name ?? "Reader"
    }

    /// Foto de perfil decodada do base64 vindo do backend (se houver).
    private var avatarImage: UIImage? {
        guard let base64 = authManager.currentUser?.avatar,
              let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
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
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        ZStack(alignment: .bottomTrailing) {
                            avatarView
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(7)
                                .background(Circle().fill(Color.emphasis))
                                .overlay(Circle().stroke(.backgroundPrimary, lineWidth: 2))
                        }
                    }
                    .disabled(authManager.isLoading)

                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.title2.weight(.bold))
                        Button {
                            draftName = authManager.currentUser?.name ?? ""
                            showEditName = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.emphasis)
                        }
                        .disabled(authManager.isLoading)
                    }

                    if !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secundaryLabel)
                    }

                    if avatarImage != nil {
                        Button(Localization.Profile.removePhoto.string) {
                            Task { await authManager.removeAvatar() }
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.red)
                        .disabled(authManager.isLoading)
                    }
                }
                .padding(.top, 16)

                genresSection

                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Text(Localization.Profile.signOut.string)
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

                Button(role: .destructive) {
                    showDeleteAccountConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        if authManager.isLoading {
                            ProgressView()
                        }
                        Text(Localization.Profile.deleteAccount.string)
                            .font(.system(.subheadline, weight: .semibold))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .disabled(authManager.isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(.backgroundPrimary)
        .navigationTitle(Localization.Profile.title.string)
        .confirmationDialog(Localization.Profile.signOutConfirmTitle.string, isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button(Localization.Profile.signOut.string, role: .destructive) {
                authManager.signOut()
            }
            Button(Localization.Generic.cancel.string, role: .cancel) {}
        }
        .alert(Localization.Profile.deleteAccountConfirmTitle.string, isPresented: $showDeleteAccountConfirmation) {
            Button(Localization.Profile.deleteAccountConfirmAction.string, role: .destructive) {
                Task {
                    let ok = await authManager.deleteAccount()
                    if !ok { showDeleteAccountError = true }
                }
            }
            Button(Localization.Generic.cancel.string, role: .cancel) {}
        } message: {
            Text(Localization.Profile.deleteAccountConfirmMessage.string)
        }
        .alert(Localization.Generic.error.string, isPresented: $showDeleteAccountError) {
            Button(Localization.Generic.ok.string, role: .cancel) {}
        } message: {
            Text(authManager.errorMessage ?? "")
        }
        .alert(Localization.Profile.editName.string, isPresented: $showEditName) {
            TextField(Localization.Profile.namePlaceholder.string, text: $draftName)
            Button(Localization.Generic.save.string) {
                let newName = draftName
                Task { await authManager.updateName(newName) }
            }
            Button(Localization.Generic.cancel.string, role: .cancel) {}
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let base64 = image.compressedBase64() {
                    await authManager.updateAvatar(base64)
                }
                selectedPhoto = nil
            }
        }
    }

    /// Avatar: foto do usuário (se houver) ou o ícone padrão.
    @ViewBuilder
    private var avatarView: some View {
        if let image = avatarImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 84))
                .foregroundStyle(.emphasis)
                .frame(width: 96, height: 96)
        }
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Localization.Profile.yourGenres.string)
                    .font(.system(.title3, weight: .bold))
                Spacer()
                if !availableToAdd.isEmpty {
                    Menu {
                        ForEach(availableToAdd) { genre in
                            Button {
                                add(genre)
                            } label: {
                                Label(title: { Text(genre.localizedTitle) }, icon: { Image(systemName: genre.icon) })
                            }
                        }
                    } label: {
                        Label(Localization.Generic.add.string, systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.emphasis)
                    }
                    .disabled(authManager.isLoading)
                }
            }

            if chosenGenres.isEmpty {
                Text(Localization.Profile.noGenres.string)
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
            Text(genre.localizedTitle)
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
