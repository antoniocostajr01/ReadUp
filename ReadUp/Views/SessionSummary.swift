import SwiftUI
import Foundation

struct SessionSummary: View {
    @Environment(LibraryStore.self) private var store
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SessionSummaryViewModel
    @State private var shareURL: URL?
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var coverImage: UIImage?
    @State private var isShowingClipboardToast = false
    var onSessionSaved: (() -> Void)? = nil

    init(readingTime: Int, currentBook: Book, pagesRead: Int, previousProgress: Int, onSessionSaved: (() -> Void)? = nil, sessionToEdit: LiterarySession? = nil) {
        self.onSessionSaved = onSessionSaved
        self._viewModel = State(initialValue: SessionSummaryViewModel(readingTime: readingTime, currentBook: currentBook, pagesRead: pagesRead, previousProgress: previousProgress, sessionToEdit: sessionToEdit))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.cardInset) {
                headerCard

                totalProgressCard

                HStack(spacing: 10) {
                    StatCard(icon: "book.pages", title: Localization.SessionSummary.pagesRead.string, value: "\(viewModel.sessionPagesRead)")
                    StatCard(icon: "timer", title: Localization.SessionSummary.sessionTime.string, value: viewModel.sessionTimeFormatted)
                }

                HStack(spacing: 10) {
                    StatCard(icon: "chart.line.uptrend.xyaxis", title: Localization.SessionSummary.totalCompletion.string, value: "\(viewModel.completionPercentage)%")
                }

                Text(Localization.SessionSummary.finalThoughts.string)
                    .font(.system(.title3, weight: .bold))

                TextField(Localization.SessionSummary.thoughtsPlaceholder.string, text: $viewModel.thoughts, axis: .vertical)
                    .lineLimit(5...10)
                    .padding(Spacing.md)
                    .cardSurface(radius: Radius.md)

                confirmButton

                instagramShareSection
            }
            .padding(Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
        .background(.surface)
        .navigationTitle(Localization.SessionSummary.title.string)
        .navigationBarTitleDisplayMode(.inline)
        // Sessão recém-concluída: só sai daqui confirmando. Ao editar uma sessão
        // antiga (vinda de Home/History), o voltar continua disponível.
        .navigationBarBackButtonHidden(viewModel.sessionToEdit == nil)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if shareURL != nil {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary) // Disabled state while generating
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
                    .presentationDetents([.medium, .large])
            }
        }
        .overlay(alignment: .bottom) {
            if isShowingClipboardToast {
                clipboardToast
            }
        }
        .onAppear(perform: viewModel.setupForEditting)
        .onDisappear {
            // Rede de segurança: garante que a sessão seja registrada ao finalizar,
            // mesmo que o usuário saia sem tocar em Confirmar (ex.: swipe back).
            guard viewModel.sessionToEdit == nil, !viewModel.hasSaved else { return }
            Task { await viewModel.saveSession(store: store, onSessionSaved: onSessionSaved, onDismiss: {}) }
        }
        .task {
            // Carrega a capa (por URL) antes de renderizar o card de compartilhamento,
            // pois o ImageRenderer é síncrono e não aguarda um AsyncImage.
            coverImage = await GoogleBooksService().loadImageData(from: viewModel.currentBook.coverUrl.flatMap(URL.init(string:)))
                .flatMap(UIImage.init(data:))
            renderShareImage()
        }
    }

    private var confirmButton: some View {
        Button(action: {
            Task { await viewModel.saveSession(store: store, onSessionSaved: onSessionSaved, onDismiss: { dismiss() }) }
        }) {
            Label(Localization.SessionSummary.saveSession.string, systemImage: "checkmark.circle")
                .font(.titleTertiary)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.cardInset)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.brand)
                )
        }
        .disabled(viewModel.isSaving)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Compartilhamento no Instagram

    private var instagramShareSection: some View {
        VStack(spacing: Spacing.sm) {
            Button(action: shareToInstagram) {
                Label(Localization.SessionSummary.shareToInstagram.string, systemImage: "camera.fill")
                    .font(.headingRow)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.cardInset)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(instagramGradient)
                    )
            }
            .disabled(shareImage == nil)
            .opacity(shareImage == nil ? 0.5 : 1)

            Label(Localization.SessionSummary.clipboardInstruction.string, systemImage: "doc.on.clipboard")
                .font(.captionDefault)
                .foregroundStyle(.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var instagramGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.40, green: 0.22, blue: 0.72),
                Color(red: 0.83, green: 0.18, blue: 0.42),
                Color(red: 0.98, green: 0.51, blue: 0.23)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var clipboardToast: some View {
        Label(Localization.SessionSummary.clipboardCopied.string, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Capsule().fill(Color.black.opacity(0.85)))
            .padding(.bottom, Spacing.xl)
            .padding(.horizontal, Spacing.xl)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// Copia a imagem do resumo para a área de transferência e abre a câmera de
    /// stories do Instagram, para o usuário colar a foto no story.
    private func shareToInstagram() {
        guard let shareImage else { return }
        UIPasteboard.general.image = shareImage

        withAnimation { isShowingClipboardToast = true }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { isShowingClipboardToast = false }
        }

        let candidates = ["instagram://story-camera", "instagram-stories://share"]
        for urlString in candidates {
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }

        // Instagram não instalado → cai no share sheet padrão do sistema.
        showShareSheet = true
    }

    @MainActor
    private func renderShareImage() {
        let viewToRender = SessionSummaryShareCard(
            currentBook: viewModel.currentBook,
            coverImage: coverImage,
            sessionPagesRead: viewModel.sessionPagesRead,
            sessionTime: viewModel.sessionTimeFormatted,
            totalProgress: viewModel.pagesRead,
            userName: authManager.currentUser?.name ?? "Reader",
            userAvatar: authManager.currentUser?.avatar
                .flatMap { Data(base64Encoded: $0) }
                .flatMap { UIImage(data: $0) }
        )
        let renderer = ImageRenderer(content: viewToRender)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = false // Transparent background

        if let uiImage = renderer.uiImage, let pngData = uiImage.pngData() {
            shareImage = uiImage
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReadUp_Session.png")
            do {
                try pngData.write(to: tempURL)
                shareURL = tempURL
            } catch {
                print("Error saving transparent PNG: \(error)")
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: Spacing.cardInset) {
            BookCoverView(coverUrl: viewModel.currentBook.coverUrl, width: 92, height: 132)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.currentBook.title)
                    .font(.titleSecondary)
                    .lineLimit(2)

                Text(viewModel.currentBook.author)
                    .font(.title3)
                    .foregroundStyle(.inkMuted)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(Spacing.cardInset)
        .cardSurface(radius: Radius.lg)
    }

    private var totalProgressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(Localization.SessionSummary.totalProgress.string, systemImage: "book")
                .font(.bodySupporting)
                .foregroundStyle(.inkMuted)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("\(viewModel.pagesRead)")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(.brand)
                Text("/ \(viewModel.currentBook.numberOfPages) \(Localization.SessionSummary.ofPages.string)")
                    .font(.title3)
                    .foregroundStyle(.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .cardSurface(radius: Radius.lg)
    }
}

fileprivate struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
