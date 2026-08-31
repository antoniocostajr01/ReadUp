import SwiftUI
import PhotosUI

struct Profile: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(LibraryStore.self) private var store
    @State private var viewModel = HomeViewModel()
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

    /// Iniciais do nome — o avatar do Figma é tipográfico quando não há foto.
    private var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
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
            VStack(alignment: .leading, spacing: 22) {
                identity
                stats
                genresSection
                settings
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .toolbar(.hidden, for: .navigationBar)
        .frame(maxWidth: .infinity)
        .background(Palette.surface)
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

    // MARK: - Identidade

    /// Avatar, nome e "editar perfil" numa linha. Figma `41:1089`.
    private var identity: some View {
        HStack(spacing: Spacing.lg) {
            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                avatarView
            }
            .disabled(authManager.isLoading)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(displayName)
                    .textStyle(.titleBook)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)

                Button {
                    draftName = authManager.currentUser?.name ?? ""
                    showEditName = true
                } label: {
                    Text(Localization.Profile.editProfile.string)
                        .textStyle(.captionDefault)
                        .foregroundStyle(Palette.ink)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)

                if avatarImage != nil {
                    Button(Localization.Profile.removePhoto.string) {
                        Task { await authManager.removeAvatar() }
                    }
                    .textStyle(.captionDefault)
                    .foregroundStyle(Palette.danger)
                    .disabled(authManager.isLoading)
                }
            }

            Spacer(minLength: 0)
        }
    }

    /// Avatar: foto do usuário (se houver) ou as iniciais em serifada.
    @ViewBuilder
    private var avatarView: some View {
        if let image = avatarImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Spacing.avatar, height: Spacing.avatar)
                .clipShape(Circle())
        } else {
            Text(initials)
                .textStyle(.titleBook)
                .foregroundStyle(Palette.inkStrongMuted)
                .frame(width: Spacing.avatar, height: Spacing.avatar)
                .background(Circle().fill(Palette.surfaceSunken))
        }
    }

    // MARK: - Métricas

    /// Livros, sessões e sequência. Figma `41:1095`.
    private var stats: some View {
        HStack(spacing: 10) {
            statTile(Localization.Profile.statBooks.string, "\(store.books.count)")
            statTile(Localization.Profile.statSessions.string, "\(store.sessions.count)")
            statTile(
                Localization.Profile.statStreak.string,
                "\(viewModel.currentSessionStreak(from: store.sessions))"
            )
        }
    }

    private func statTile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label.uppercased())
                .textStyle(.overline)
                .foregroundStyle(Palette.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .textStyle(.displayMetric)
                .foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .cardSurface(radius: Radius.cardSm)
    }

    // MARK: - Ajustes

    /// Linhas separadas por régua, sem card. Figma `41:1125`.
    private var settings: some View {
        VStack(spacing: 0) {
            settingsRow(Localization.Profile.notifications.string) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            settingsRow(Localization.Profile.signOut.string) {
                showSignOutConfirmation = true
            }

            Button {
                showDeleteAccountConfirmation = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    if authManager.isLoading { ProgressView() }
                    Text(Localization.Profile.deleteAccount.string)
                        .textStyle(.bodyDefault)
                        .foregroundStyle(Palette.danger)
                    Spacer()
                }
                .padding(.vertical, Spacing.cardInset)
                .overlay(alignment: .top) {
                    Rectangle().fill(Palette.divider).frame(height: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(authManager.isLoading)
        }
    }

    private func settingsRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .textStyle(.bodyDefault)
                    .foregroundStyle(Palette.ink)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.iconLabel)
                    .foregroundStyle(Palette.inkDisclosure)
            }
            .contentShape(.rect)
            .padding(.vertical, Spacing.cardInset)
            .overlay(alignment: .top) {
                Rectangle().fill(Palette.divider).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(Localization.Profile.yourGenres.string)
                    .textStyle(.titleSecondary)
                    .foregroundStyle(Palette.ink)
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
                        Text(Localization.Generic.add.string)
                            .textStyle(.label)
                            .foregroundStyle(Palette.ink)
                    }
                    .disabled(authManager.isLoading)
                }
            }

            if chosenGenres.isEmpty {
                Text(Localization.Profile.noGenres.string)
                    .textStyle(.bodySupporting)
                    .foregroundStyle(Palette.inkMuted)
            } else {
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(chosenGenres) { genre in
                        chip(for: genre)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Chip com o "✕" removendo o gênero. Figma `41:1110`.
    private func chip(for genre: Genre) -> some View {
        HStack(spacing: 7) {
            Text(genre.localizedTitle)
                .textStyle(.label)
                .lineLimit(1)
                .fixedSize()

            Button {
                remove(genre)
            } label: {
                Image(systemName: "xmark")
                    .font(.captionDefault)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(genre.localizedTitle)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 15)
        .padding(.vertical, 9)
        .background(Capsule().fill(Palette.surfaceFill))
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
