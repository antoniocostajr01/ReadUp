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
            VStack(spacing: Spacing.xl) {
                // Cabeçalho do usuário
                VStack(spacing: Spacing.sm) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        ZStack(alignment: .bottomTrailing) {
                            avatarView
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(7)
                                .background(Circle().fill(Color.brand))
                                .overlay(Circle().stroke(.surface, lineWidth: 2))
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
                                .font(.bodySupportingStrong)
                                .foregroundStyle(.brand)
                        }
                        .disabled(authManager.isLoading)
                    }

                    if !email.isEmpty {
                        Text(email)
                            .font(.bodySupporting)
                            .foregroundStyle(.inkMuted)
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
                .padding(.top, Spacing.lg)

                genresSection

                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Text(Localization.Profile.signOut.string)
                        .font(.headingRow)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .cardSurface(radius: Radius.lg)
                }
                .padding(.top, Spacing.sm)

                Button(role: .destructive) {
                    showDeleteAccountConfirmation = true
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if authManager.isLoading {
                            ProgressView()
                        }
                        Text(Localization.Profile.deleteAccount.string)
                            .font(.system(.subheadline, weight: .semibold))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.cardInset)
                }
                .disabled(authManager.isLoading)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(.surface)
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
                .foregroundStyle(.brand)
                .frame(width: 96, height: 96)
        }
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
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
                            .font(.bodySupportingStrong)
                            .foregroundStyle(.brand)
                    }
                    .disabled(authManager.isLoading)
                }
            }

            if chosenGenres.isEmpty {
                Text(Localization.Profile.noGenres.string)
                    .font(.bodySupporting)
                    .foregroundStyle(.inkMuted)
            } else {
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(chosenGenres) { genre in
                        chip(for: genre)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardSurface(radius: Radius.xl)
    }

    private func chip(for genre: Genre) -> some View {
        HStack(spacing: 6) {
            Image(systemName: genre.icon)
                .font(.caption)
            Text(genre.localizedTitle)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .fixedSize()
            Button {
                remove(genre)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.inkMuted)
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .foregroundStyle(.brand)
        .background(
            Capsule().fill(Color.brand.opacity(0.14))
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

/// Quebra os chips em linhas conforme a largura disponível, cada um com a sua
/// largura natural — diferente do LazyVGrid, que força colunas de largura igual.
fileprivate struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > width {
                totalHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += rowWidth > 0 ? spacing + size.width : size.width
                rowHeight = max(rowHeight, size.height)
            }
        }

        return CGSize(width: width == .infinity ? rowWidth : width, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        Profile()
            .environment(AuthManager())
    }
}
