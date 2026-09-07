import SwiftUI
import PhotosUI
import UserNotifications

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
    @State private var showPhotoPicker = false
    @State private var showGenrePicker = false

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
        // Mesma forma da exclusão de conta: sair é destrutivo o bastante para merecer um
        // alerta com explicação, não um balão de ação.
        .alert(Localization.Profile.signOutConfirmTitle.string, isPresented: $showSignOutConfirmation) {
            Button(Localization.Profile.signOut.string, role: .destructive) {
                authManager.signOut()
            }
            Button(Localization.Generic.cancel.string, role: .cancel) {}
        } message: {
            Text(Localization.Profile.signOutConfirmMessage.string)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images, photoLibrary: .shared())
        .fullScreenCover(isPresented: $showGenrePicker) {
            GenreOnboardingView(mode: .editing, preselected: authManager.genres)
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

    /// Avatar e nome, com o "editar perfil" como botão de verdade logo abaixo.
    /// Figma `41:1089`.
    ///
    /// Antes o editar era um link de texto de 13pt que só trocava o nome, e a foto se
    /// mudava tocando no avatar — dois caminhos escondidos. Agora é uma pílula da mesma
    /// família dos outros botões do app, e ela abre a escolha entre foto e nome.
    private var identity: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.lg) {
                avatarView

                Text(displayName)
                    .textStyle(.titleBook)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }

            // `Menu` e não um diálogo: as opções saem do próprio botão, ancoradas nele,
            // em vez de um balão no meio da tela. O label é a mesma pílula que o
            // `ReadUpButton` desenha.
            Menu {
                Button {
                    showPhotoPicker = true
                } label: {
                    Label(Localization.Profile.changePhoto.string, systemImage: "photo")
                }

                Button {
                    draftName = authManager.currentUser?.name ?? ""
                    showEditName = true
                } label: {
                    Label(Localization.Profile.editName.string, systemImage: "pencil")
                }

                if avatarImage != nil {
                    Button(role: .destructive) {
                        Task { await authManager.removeAvatar() }
                    } label: {
                        Label(Localization.Profile.removePhoto.string, systemImage: "trash")
                    }
                }
            } label: {
                ReadUpButtonLabel(
                    title: Localization.Profile.editProfile.string,
                    variant: .secondary,
                    isLoading: authManager.isLoading
                )
            }
            .disabled(authManager.isLoading)
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
                Task { await openNotificationSettings() }
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
                // Abre a mesma tela de chips caindo do onboarding, com os gêneros atuais
                // já marcados — em vez de um menu de lista, que não se parecia com nada
                // mais no app.
                Button {
                    showGenrePicker = true
                } label: {
                    Text(Localization.Generic.add.string)
                        .textStyle(.label)
                        .foregroundStyle(Palette.ink)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)
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

    /// Leva às notificações do ReadUp nos Ajustes do iOS.
    ///
    /// `openSettingsURLString` só tem para onde ir depois que o app pediu alguma
    /// permissão — sem isso ele não tem página nos Ajustes, e era por isso que tocar
    /// aqui não fazia nada: o ReadUp nunca pediu nenhuma. Então o primeiro toque pede a
    /// autorização de notificação, que é o que esta linha promete; do segundo em diante
    /// o link abre a página do app.
    private func openNotificationSettings() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        if status == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
            return
        }

        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        await UIApplication.shared.open(url)
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
