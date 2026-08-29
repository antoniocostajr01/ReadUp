import SwiftUI
import VisionKit

/// Tela cheia de câmera para escanear vários ISBNs em sequência. A lista dos livros
/// escaneados fica numa sheet parcial por cima, deixando a câmera visível/utilizável.
struct ISBNScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LibraryStore.self) private var store

    @State private var viewModel = ISBNScannerViewModel()
    @State private var isAdding = false

    private var isCameraAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        ZStack {
            if isCameraAvailable {
                ISBNScannerRepresentable(onScan: viewModel.handle)
                    .ignoresSafeArea()
            } else {
                ContentUnavailableView(
                    Localization.Scan.cameraUnavailableTitle.string,
                    systemImage: "camera.fill",
                    description: Text(Localization.Scan.cameraUnavailableMessage.string)
                )
            }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.iconLabel)
                            .foregroundStyle(.ink)
                            .padding(10)
                            .background(Circle().fill(.inkInverse))
                    }
                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)

                Spacer()

                if isCameraAvailable {
                    Text(Localization.Scan.instructions.string)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.cardInset)
                        .padding(.vertical, Spacing.sm)
                        .background(Capsule().fill(.black.opacity(0.6)))
                        .padding(.bottom, Spacing.md)
                }
            }
        }
        .sheet(isPresented: .constant(true)) {
            scannedListSheet
                .presentationDetents([.height(180), .medium, .large])
                // Vidro em vez de preto sólido: a câmera continua legível atrás da lista,
                // que é o ponto de manter a sheet aberta enquanto se escaneia.
                .presentationBackground(.regularMaterial)
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
        }
    }

    private var scannedListSheet: some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 0) {
            if viewModel.scanned.isEmpty {
                Text(Localization.Scan.emptyList.string)
                    .font(.bodySupporting)
                    .foregroundStyle(.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xl)
                Spacer()
            } else {
                List {
                    // Binding por elemento em vez de procurar o índice no toque: o
                    // `firstIndex` rodava sobre uma cópia do array e falhava calado
                    // quando a linha saía da lista entre o render e o toque.
                    ForEach($viewModel.scanned) { $row in
                        scannedRow($row)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.remove(viewModel.scanned[index])
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            addButton
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
        }
    }

    private func scannedRow(_ row: Binding<ISBNScannerViewModel.ScannedBook>) -> some View {
        let book = row.wrappedValue

        return HStack(spacing: Spacing.md) {
            cover(for: book)
                .frame(width: 40, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                switch book.state {
                case .resolving:
                    ProgressView()
                    Text(book.isbn)
                        .font(.captionDefault)
                        .foregroundStyle(.inkMuted)
                case .found(let found):
                    Text(found.title)
                        .font(.bodySupportingStrong)
                        .lineLimit(1)
                    Text(found.author)
                        .font(.captionDefault)
                        .foregroundStyle(.inkMuted)
                        .lineLimit(1)
                    // Em linha própria: disputando a horizontal com o título, a cápsula
                    // era cortada ao trocar pra um status mais comprido.
                    statusMenu(selection: row.status)
                        .padding(.top, 2)
                case .notFound:
                    Text(Localization.Scan.notFound.string)
                        .font(.bodySupportingStrong)
                    Text(book.isbn)
                        .font(.captionDefault)
                        .foregroundStyle(.inkMuted)
                }
            }
            Spacer(minLength: 8)

            // Botão explícito além do swipe: com a câmera aberta o usuário precisa
            // corrigir um código errado na hora, sem descobrir um gesto escondido.
            Button {
                viewModel.remove(book)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundStyle(.inkMuted)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.Generic.delete.string)
        }
        .padding(.vertical, Spacing.xs)
    }

    @ViewBuilder
    private func cover(for book: ISBNScannerViewModel.ScannedBook) -> some View {
        if case .found(let found) = book.state {
            AsyncImage(url: found.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.surfaceFill
                }
            }
        } else {
            Color.surfaceFill
        }
    }

    private func statusMenu(selection: Binding<BookStatus>) -> some View {
        Menu {
            Picker("", selection: selection) {
                ForEach(BookStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
        } label: {
            // Cápsula com chevron: texto solto parecia rótulo fixo, e o usuário não
            // percebia que o status vem num padrão e pode ser trocado ali mesmo.
            HStack(spacing: Spacing.xs) {
                Text(selection.wrappedValue.displayName)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.brand)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.brand.opacity(0.12))
            )
        }
    }

    private var addButton: some View {
        let foundCount = viewModel.scanned.filter { if case .found = $0.state { return true } else { return false } }.count

        return Button {
            Task {
                isAdding = true
                _ = await viewModel.addAll(to: store)
                isAdding = false
                dismiss()
            }
        } label: {
            Text(String(format: Localization.Scan.addBooks.string, foundCount))
                .font(.titleTertiary)
                .foregroundStyle(.inkInverse)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .foregroundStyle(foundCount == 0 || isAdding ? .inkMuted : .brand)
                )
        }
        .disabled(foundCount == 0 || isAdding)
    }
}

#Preview {
    ISBNScanView()
        .environment(LibraryStore())
}
