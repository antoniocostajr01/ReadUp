import SwiftUI
import VisionKit

/// Tela cheia de câmera para escanear vários ISBNs em sequência. Figma `29:142`.
///
/// O scanner é a única tela escura do sistema — a câmera é a interface, e creme por
/// cima dela não se lê. A folha com o que já foi escaneado é que volta ao creme.
struct ISBNScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LibraryStore.self) private var store

    @State private var viewModel = ISBNScannerViewModel()
    @State private var isAdding = false
    @State private var inspectedRow: ISBNScannerViewModel.ScannedBook?
    @State private var addedBook: Book?

    private var isCameraAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    private var foundCount: Int {
        viewModel.scanned.filter {
            guard case .found = $0.state else { return false }
            return !$0.isAdded
        }.count
    }

    var body: some View {
        ZStack {
            if isCameraAvailable {
                ISBNScannerRepresentable(onScan: viewModel.handle)
                    .ignoresSafeArea()
            } else {
                Palette.surfaceNight.ignoresSafeArea()
                ContentUnavailableView(
                    Localization.Scan.cameraUnavailableTitle.string,
                    systemImage: "camera.fill",
                    description: Text(Localization.Scan.cameraUnavailableMessage.string)
                )
            }

            VStack {
                HStack {
                    ChromeChip(systemImage: "xmark") { dismiss() }
                    Spacer()
                }
                .padding(.horizontal, Spacing.gutterList)
                .padding(.top, Spacing.sm)

                Spacer()

                if isCameraAvailable {
                    ScanReticle()
                        .stroke(Palette.inkOnArt, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 214, height: 128)

                    Text(Localization.Scan.instructions.string)
                        .textStyle(.bodySupporting)
                        .foregroundStyle(Palette.inkOnArt)
                        .padding(.top, Spacing.xl)
                }

                Spacer()
                Spacer()
            }
        }
        .sheet(isPresented: .constant(true)) {
            // 08c/08b e a conquista do "Add N books" têm que ser apresentados a partir
            // desta folha, não da ZStack raiz: a folha da lista fica permanentemente
            // aberta (.constant(true)), então uma segunda apresentação encadeada na MESMA
            // view de origem nunca aparece — o UIKit já tem um controller apresentado
            // dali e recusa apresentar um segundo por cima. Aninhar aqui é o padrão
            // suportado de folha-sobre-folha.
            scannedListSheet
                .presentationDetents([.height(190), .medium, .large])
                .presentationBackground(Palette.surface)
                .presentationCornerRadius(Radius.sheet)
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .sheet(item: $inspectedRow) { row in
                    ScannedBookSheet(row: row, viewModel: viewModel)
                        .presentationDetents([.large])
                        .presentationCornerRadius(Radius.sheet)
                }
                .fullScreenCover(item: $addedBook) { book in
                    BookAddedView(book: book) { dismiss() }
                }
        }
        .onAppear {
            // Todo livro escaneado precisa passar por confirmação — em vez de esperar o
            // usuário tocar a linha, a folha 08c/08b abre sozinha assim que o ISBN resolve.
            // Se já tem uma linha aberta, a nova espera na lista em vez de interromper.
            viewModel.onResolved = { book in
                guard inspectedRow == nil else { return }
                inspectedRow = book
            }
        }
    }

    // MARK: - Lista do que foi escaneado

    /// Figma `29:159`.
    private var scannedListSheet: some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(Localization.Scan.scannedTitle.string)
                    .textStyle(.titleTertiary)
                    .foregroundStyle(Palette.ink)

                Spacer()

                Text(Localization.Library.bookCount(viewModel.scanned.count))
                    .textStyle(.captionFine)
                    .foregroundStyle(Palette.inkFaint)
            }
            .padding(.horizontal, Spacing.sheetInset)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)

            if viewModel.scanned.isEmpty {
                Text(Localization.Scan.emptyList.string)
                    .textStyle(.bodySupporting)
                    .foregroundStyle(Palette.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xl)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Binding por elemento em vez de procurar o índice no toque: o
                        // `firstIndex` rodava sobre uma cópia do array e falhava calado
                        // quando a linha saía da lista entre o render e o toque.
                        ForEach($viewModel.scanned) { $row in
                            scannedRow($row)
                        }
                    }
                    .padding(.horizontal, Spacing.sheetInset)
                }
                .scrollIndicators(.never)
            }

            ReadUpButton(
                title: String(format: Localization.Scan.addBooks.string, foundCount),
                isLoading: isAdding,
                isEnabled: foundCount > 0,
                action: addAll
            )
            .padding(.horizontal, Spacing.sheetInset)
            .padding(.vertical, Spacing.md)
        }
        .background(Palette.surface)
    }

    private func addAll() {
        Task {
            isAdding = true
            let created = await viewModel.addAll(to: store)
            isAdding = false
            if let first = created.first {
                addedBook = first
            } else {
                dismiss()
            }
        }
    }

    private func scannedRow(_ row: Binding<ISBNScannerViewModel.ScannedBook>) -> some View {
        let book = row.wrappedValue

        return HStack(spacing: Spacing.md) {
            Group {
                if book.isAdded {
                    // Já persistido: a linha fica só como registro do que voltou de
                    // "Add another book", não reabre a folha de confirmação.
                    rowLabel(for: book)
                } else {
                    Button { inspectedRow = book } label: { rowLabel(for: book) }
                        .buttonStyle(.plain)
                }
            }

            if case .found = book.state, !book.isAdded {
                statusMenu(selection: row.status)
            }

            if book.isAdded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.iconLabel)
                    .foregroundStyle(Palette.brand)
                    .accessibilityLabel(Localization.Scan.added.string)
            } else {
                // Botão explícito além do swipe: com a câmera aberta o usuário precisa
                // corrigir um código errado na hora, sem descobrir um gesto escondido.
                Button {
                    viewModel.remove(book)
                } label: {
                    Image(systemName: "xmark")
                        .font(.iconLabel)
                        .foregroundStyle(Palette.inkFaint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.Generic.delete.string)
            }
        }
        .padding(.vertical, Spacing.md)
        // Sem opacidade de grupo: uma linha já adicionada recua pelo tom do título, e o
        // ✓ continua legível. Desbotar a linha inteira apagava capa, título e autor
        // junto com o sinal de que ela está pronta.
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.divider).frame(height: 1)
        }
    }

    private func rowLabel(for book: ISBNScannerViewModel.ScannedBook) -> some View {
        HStack(spacing: Spacing.md) {
            cover(for: book)

            VStack(alignment: .leading, spacing: 3) {
                switch book.state {
                case .resolving:
                    Text(Localization.Scan.resolving.string)
                        .textStyle(.headingRow)
                        .foregroundStyle(Palette.inkMuted)
                    Text(book.isbn)
                        .textStyle(.captionDefault)
                        .foregroundStyle(Palette.inkMeta)

                case .found(let found):
                    Text(found.title)
                        .textStyle(.headingRow)
                        .foregroundStyle(book.isAdded ? Palette.inkDisabled : Palette.ink)
                        .lineLimit(1)
                    Text(found.author)
                        .textStyle(.captionDefault)
                        .foregroundStyle(Palette.inkMeta)
                        .lineLimit(1)

                case .notFound:
                    Text(Localization.Scan.notFound.string)
                        .textStyle(.headingRow)
                        .foregroundStyle(Palette.ink)
                    Text(book.isbn)
                        .textStyle(.captionDefault)
                        .foregroundStyle(Palette.inkMeta)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func cover(for book: ISBNScannerViewModel.ScannedBook) -> some View {
        if case .found(let found) = book.state {
            BookCoverView(
                coverUrl: found.thumbnailURL?.absoluteString,
                width: Spacing.coverRowWidth,
                height: Spacing.coverRowHeight,
                cornerRadius: Radius.coverSm,
                title: found.title,
                author: found.author
            )
        } else {
            RoundedRectangle(cornerRadius: Radius.coverSm, style: .continuous)
                .fill(Palette.surfaceSunken)
                .frame(width: Spacing.coverRowWidth, height: Spacing.coverRowHeight)
        }
    }

    /// `nil` até o usuário escolher — mostra "Select status" em vez de vir com um
    /// valor pré-marcado que o usuário nunca escolheu.
    private func statusMenu(selection: Binding<BookStatus?>) -> some View {
        Menu {
            ForEach(BookStatus.allCases, id: \.self) { status in
                Button(status.displayName) { selection.wrappedValue = status }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(selection.wrappedValue?.displayName ?? Localization.BookDetails.selectStatus.string)
                    .textStyle(.captionFine)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.captionFine)
            }
            .foregroundStyle(Palette.inkMuted)
            .fixedSize()
        }
    }
}

/// Os quatro cantos do enquadramento da câmera. Figma `29:151`.
struct ScanReticle: Shape {
    /// Comprimento de cada perna do canto.
    var arm: CGFloat = 26

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for x in [rect.minX, rect.maxX] {
            for y in [rect.minY, rect.maxY] {
                let dx: CGFloat = x == rect.minX ? arm : -arm
                let dy: CGFloat = y == rect.minY ? arm : -arm
                path.move(to: CGPoint(x: x + dx, y: y))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: y + dy))
            }
        }
        return path
    }
}

#Preview {
    ISBNScanView()
        .environment(LibraryStore())
}
