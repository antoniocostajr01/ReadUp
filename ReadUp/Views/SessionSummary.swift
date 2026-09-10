import SwiftUI
import Foundation

/// O resumo de uma sessão de leitura. Figma `10 · Session summary` (`101:300`).
///
/// O compartilhamento saiu daqui: no lugar do botão que copiava a imagem para a área
/// de transferência e mandava o usuário colar no Instagram, há um `Share` que abre o
/// fluxo próprio (`ShareFlowView`).
struct SessionSummary: View {
    @Environment(LibraryStore.self) private var store
    @Environment(AuthManager.self) private var authManager

    @State private var viewModel: SessionSummaryViewModel
    @State private var coverImage: UIImage?
    @State private var isShowingShareFlow = false
    /// Marca que o hand-off pro Instagram aconteceu, pro `onDismiss` do
    /// `fullScreenCover` saber se deve continuar a saída (modo recém-concluído) ou só
    /// voltar pro resumo (fechar pelo X, ou revendo uma sessão antiga).
    @State private var didPublish = false
    @FocusState private var isThoughtsFocused: Bool
    var onFinish: (() -> Void)? = nil

    init(readingTime: Int, currentBook: Book, pagesRead: Int, previousProgress: Int, session: LiterarySession, mode: SessionSummaryViewModel.Mode, onFinish: (() -> Void)? = nil) {
        self.onFinish = onFinish
        self._viewModel = State(initialValue: SessionSummaryViewModel(readingTime: readingTime, currentBook: currentBook, pagesRead: pagesRead, previousProgress: previousProgress, session: session, mode: mode))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                bookCard

                statsCard

                Text(Localization.SessionSummary.finalThoughts.string)
                    .textStyle(.titleSecondary)
                    .foregroundStyle(Palette.ink)
                    .padding(.top, Spacing.sm)

                TextField(Localization.SessionSummary.thoughtsPlaceholder.string, text: $viewModel.thoughts, axis: .vertical)
                    .font(.bodyDefault)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(4...8)
                    .padding(Spacing.cardInset)
                    .cardSurface(radius: Radius.field)
                    .disabled(viewModel.isReviewing && !viewModel.isEditing)
                    .focused($isThoughtsFocused)

                actions
                    .padding(.top, Spacing.lg)
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.vertical, Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
        .background(Palette.surface)
        .navigationTitle(Localization.SessionSummary.title.string)
        .navigationBarTitleDisplayMode(.inline)
        // Sessão recém-concluída: só sai daqui confirmando. Ao editar uma sessão
        // antiga (vinda de Home/History), o voltar continua disponível.
        .navigationBarBackButtonHidden(viewModel.mode == .finished)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: viewModel.isEditing) { _, isEditing in
            isThoughtsFocused = isEditing
        }
        .overlay(alignment: .bottom) {
            if viewModel.didSaveChanges || viewModel.didFailToSave {
                saveToast
            }
        }
        .animation(Motion.base, value: viewModel.didSaveChanges)
        .animation(Motion.base, value: viewModel.didFailToSave)
        .task(id: viewModel.didSaveChanges || viewModel.didFailToSave) {
            guard viewModel.didSaveChanges || viewModel.didFailToSave else { return }
            try? await Task.sleep(for: .seconds(2))
            viewModel.didSaveChanges = false
            viewModel.didFailToSave = false
        }
        .fullScreenCover(isPresented: $isShowingShareFlow, onDismiss: {
            // Publicou de verdade (não só fechou pelo X) e a sessão acabou de ser
            // concluída: o Instagram já ficou com o card, então volta pra Home em vez
            // de deixar o usuário parado no resumo. Revendo uma sessão antiga, o
            // publish sempre volta pro resumo — comportamento de hoje, inalterado.
            if didPublish, viewModel.mode == .finished {
                onFinish?()
            }
            didPublish = false
        }) {
            ShareFlowView(story: story, onPublished: { didPublish = true })
        }
        .onAppear(perform: viewModel.setupForEditting)
        .task {
            // A capa é resolvida aqui, e não no card de compartilhamento, porque o
            // `ImageRenderer` é síncrono e não aguarda um `AsyncImage`.
            //
            // Pelo `CoverImageCache`, o mesmo cache que desenha a capa no card acima:
            // baixar de novo por fora dele dava um card com o placeholder tipográfico
            // enquanto a capa real estava na memória a duas views de distância.
            guard let url = viewModel.currentBook.coverUrl.flatMap(URL.init(string:)) else { return }
            coverImage = await CoverImageCache.load(url)
        }
    }

    /// A capa já baixada, lida de forma síncrona. `nil` só se ela de fato nunca chegou.
    private var cachedCover: UIImage? {
        viewModel.currentBook.coverUrl
            .flatMap(URL.init(string:))
            .flatMap(CoverImageCache.image(for:))
    }

    /// Os dados que o fluxo de compartilhamento consome.
    private var story: SessionStory {
        SessionStory(
            book: viewModel.currentBook,
            // Se o toque em Share vier antes da `.task` resolver, ainda assim a capa
            // sai do cache — que já a tem, porque o card acima acabou de desenhá-la.
            coverImage: coverImage ?? cachedCover,
            pagesRead: viewModel.sessionPagesRead,
            sessionTime: viewModel.sessionTimeFormatted,
            totalProgress: viewModel.pagesRead,
            completionPercentage: viewModel.completionPercentage,
            userName: authManager.currentUser?.displayName ?? "Reader",
            userAvatar: authManager.currentUser?.avatarImage
        )
    }

    // MARK: - Blocos

    private var bookCard: some View {
        HStack(spacing: Spacing.cardInset) {
            BookCoverView(
                coverUrl: viewModel.currentBook.coverUrl,
                width: 127,
                height: 184,
                cornerRadius: Radius.cover,
                title: viewModel.currentBook.title,
                author: viewModel.currentBook.author
            )
            .coverShadow()

            VStack(alignment: .leading, spacing: Spacing.xs + 2) {
                Text(viewModel.currentBook.title)
                    .textStyle(.titleCard)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(3)

                Text(viewModel.currentBook.author)
                    .textStyle(.authorRow)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ProgressTrack(value: Double(viewModel.completionPercentage) / 100)

                    Text(verbatim: "\(viewModel.pagesRead) / \(viewModel.currentBook.numberOfPages) \(Localization.SessionSummary.ofPages.string)")
                        .textStyle(.captionDefault)
                        .foregroundStyle(Palette.inkMeta)
                }
                .padding(.top, Spacing.sm)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.cardInset)
        .cardSurface(radius: Radius.card)
    }

    /// As três medidas num card só, separadas por fio — o padrão do Home v2.
    private var statsCard: some View {
        HStack(spacing: 0) {
            statCell(Localization.SessionSummary.pagesRead.string, "\(viewModel.sessionPagesRead)")
            rule
            statCell(Localization.SessionSummary.sessionTime.string, viewModel.sessionTimeFormatted)
            rule
            statCell(Localization.SessionSummary.totalCompletion.string, "\(viewModel.completionPercentage)%")
        }
        .padding(.vertical, Spacing.lg)
        .cardSurface(radius: Radius.cardSm)
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: Spacing.sm + 2) {
            Text(label)
                .textStyle(.overline)
                .textCase(.uppercase)
                .foregroundStyle(Palette.inkStrongMuted)
                .lineLimit(1)

            Text(value)
                .textStyle(.displayMetric)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var rule: some View {
        Rectangle()
            .fill(Palette.rule)
            .frame(width: 1, height: 40)
    }

    /// Uma pílula preta por tela, e ela fica sempre no topo da pilha.
    ///
    /// Revendo uma sessão antiga é o **mesmo botão** que vira Save: entrar em edição
    /// não troca a posição nem a cor do alvo, só o rótulo. Duas pílulas trocando de
    /// lugar a cada toque fariam o usuário reprocurar o botão que ele acabou de usar.
    @ViewBuilder
    private var actions: some View {
        VStack(spacing: Spacing.md) {
            if viewModel.isReviewing {
                ReadUpButton(
                    title: viewModel.isEditing
                        ? Localization.SessionSummary.saveChanges.string
                        : Localization.SessionSummary.editSession.string,
                    isLoading: viewModel.isSaving
                ) {
                    if viewModel.isEditing {
                        Task { await viewModel.updateSession(store: store) }
                    } else {
                        viewModel.isEditing = true
                    }
                }

                // Desabilitado durante a edição: o card compartilhado é renderizado a
                // partir do que está gravado, então sair para compartilhar no meio de
                // uma alteração não salva publicaria o texto antigo.
                shareButton(variant: .secondary, isEnabled: !viewModel.isEditing)
            } else {
                ReadUpButton(
                    title: Localization.SessionSummary.backToHome.string,
                    isLoading: viewModel.isSaving
                ) {
                    Task {
                        await viewModel.finish(store: store)
                        onFinish?()
                    }
                }

                shareButton(variant: .secondary, isEnabled: true)
            }
        }
    }

    private func shareButton(variant: ReadUpButton.Variant, isEnabled: Bool) -> some View {
        ReadUpButton(
            title: Localization.SessionSummary.share.string,
            variant: variant,
            isEnabled: isEnabled
        ) {
            isShowingShareFlow = true
        }
    }

    // MARK: - Retorno da gravação

    /// A confirmação de que a alteração foi gravada.
    ///
    /// Some sozinha: é uma confirmação, não uma decisão — não deve pedir um toque.
    private var saveToast: some View {
        let failed = viewModel.didFailToSave
        return Label(
            failed
                ? Localization.SessionSummary.changesFailed.string
                : Localization.SessionSummary.changesSaved.string,
            systemImage: failed ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
        )
        .textStyle(.label)
        .foregroundStyle(Palette.inkInverse)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Capsule().fill(failed ? Palette.danger : Palette.ink))
        .padding(.bottom, Spacing.xl)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
