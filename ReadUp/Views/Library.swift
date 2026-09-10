//
//  Library.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct Library: View {
    @Environment(LibraryStore.self) private var store
    @Environment(TabBarVisibility.self) private var tabBarVisibility

    private var books: [Book] { store.books }

    @State private var selectedBook: Book?
    @State private var searchText = ""
    /// O status que filtra a grade. `nil` é "Todos".
    @State private var statusFilter: BookStatus?
    private enum AddOption { case scan, search, manual }

    @State private var isShowingAddOptions = false
    @State private var pendingOption: AddOption?
    @Namespace private var addButtonNamespace
    // A capa tocada é promovida à camada da frente e voa da grade até o herói do
    // detalhe, sem nunca sair de tela. Anotação do Figma `47:1906`.
    @State private var frameStore = CoverFrameStore()
    /// O livro cuja capa está na camada da frente. Sobrevive ao fecho: só sai quando o
    /// voo de volta termina, senão a capa reapareceria na grade a meio caminho.
    @State private var flyingBook: Book?
    @State private var heroPlacement = HeroPlacement()
    /// `true` durante o voo. Fora dele o `placement` muda por scroll, e mola nenhuma.
    @State private var isFlying = false
    /// Identifica o voo em curso. A `completion` de um `withAnimation` chega no fim da
    /// mola — se nesse meio tempo outro voo começou (fechar um livro e abrir o seguinte
    /// antes de a animação acabar), a conclusão antiga não pode mexer em mais nada:
    /// era ela que apagava o `flyingBook` do livro recém-aberto, deixando o detalhe sem
    /// capa e a capa da grade parada por cima dele.
    @State private var flightID = 0
    @State private var isShowingScanner = false
    @State private var isShowingSearch = false
    @State private var isShowingAddManually = false
    /// A altura do chrome fixo, medida: é ela que dá o respiro do topo da grade.
    @State private var chromeHeight: CGFloat = 180
    /// A largura da grade, medida uma vez, para não pôr um `GeometryReader` por célula.
    @State private var gridWidth: CGFloat = 0

    /// Ordem do Figma, não a do enum: Lendo primeiro, abandonados por último.
    private let shelfOrder: [BookStatus] = [.reading, .iWantToRead, .read, .rereading, .abandoned]

    /// Livros filtrados pela busca (título ou autor). Sem texto, retorna todos.
    private var filteredBooks: [Book] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.author.localizedCaseInsensitiveContains(query)
        }
    }

    /// O que a grade mostra: a busca, depois o filtro de status.
    private var visibleBooks: [Book] {
        let source = statusFilter.map { status in filteredBooks.filter { $0.status == status } }
            ?? filteredBooks
        return source.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var columnWidth: CGFloat {
        max(0, (gridWidth - Spacing.lg) / 2)
    }

    var body: some View {
        // Três camadas. A de baixo troca (grade ↔ detalhe), a do meio é a grade, que
        // **nunca é desmontada** — é isso que deixa as capas explodirem por cima do
        // detalhe em vez de sumirem com a tela. A da frente é a capa que voa.
        ZStack(alignment: .top) {
            if let book = selectedBook {
                BookDetailsView(
                    source: .library(book),
                    onHeroPlacement: place,
                    onClose: { select(nil) }
                )
                .transition(.opacity)
            }

            grid
                .allowsHitTesting(selectedBook == nil)

            topChrome
                .opacity(selectedBook == nil ? 1 : 0)
                .allowsHitTesting(selectedBook == nil)

            // Camada da frente: a capa, que fica.
            if let flyingBook, heroPlacement.isPlaced {
                FlyingCover(
                    coverUrl: flyingBook.coverUrl,
                    title: flyingBook.title,
                    author: flyingBook.author,
                    placement: heroPlacement
                )
            }
        }
        .coordinateSpace(.named(HeroSpace.name))
        .background(Palette.surface)
        // Tocar fora do campo fecha o teclado. `simultaneousGesture` para não roubar o
        // toque das capas nem dos chips de filtro — o mesmo par que a `SessionSummary`
        // já usa.
        .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .navigationBar)
        // A tela escolhida abre no onDismiss, não no toque: apresentar uma sheet enquanto
        // outra ainda está saindo faz o SwiftUI engolir a segunda.
        .sheet(isPresented: $isShowingAddOptions, onDismiss: openPendingOption) {
            addOptionsSheet
                .navigationTransition(.zoom(sourceID: "addBook", in: addButtonNamespace))
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            ISBNScanView()
        }
        // Sem NavigationStack: a Search desenha o próprio chip de voltar (Figma `47:1669`).
        .sheet(isPresented: $isShowingSearch) {
            Search()
        }
        .sheet(isPresented: $isShowingAddManually) {
            BookFormView(mode: .create)
        }
    }

    /// Abre ou fecha o detalhe, promovendo a capa tocada à camada da frente.
    private func select(_ book: Book?) {
        flightID += 1
        let flight = flightID

        if let book {
            // A capa arranca de onde está na grade, sem animação: só depois o
            // detalhe se compõe e diz para onde ela vai.
            flyingBook = book
            // Sem frame de origem (capa nunca medida) não há de onde voar: a capa
            // aparece já no lugar quando o detalhe disser onde é. Nunca fica sem capa.
            if let origin = frameStore.frame(for: book.id) {
                heroPlacement = HeroPlacement(frame: origin)
                isFlying = true
            } else {
                heroPlacement = HeroPlacement()
                isFlying = false
            }
            withAnimation(Motion.heroFlight) {
                selectedBook = book
                tabBarVisibility.isHidden = true
            }
        } else {
            isFlying = true
            let origin = flyingBook.flatMap { frameStore.frame(for: $0.id) }
            withAnimation(Motion.heroFlight) {
                selectedBook = nil
                tabBarVisibility.isHidden = false
                if let origin { heroPlacement = HeroPlacement(frame: origin) }
            } completion: {
                guard flight == flightID else { return }
                flyingBook = nil
                isFlying = false
            }
            endFlightIfStuck(flight, clearsFlyingBook: true)
        }
    }

    /// Rede de segurança: a `completion` do `withAnimation` às vezes não chega — SwiftUI
    /// a perde quando várias capas mudam de geometria no mesmo instante (fechar um livro
    /// enquanto o scroll ainda estava se ajustando, por exemplo). Sem isto `isFlying`
    /// ficava preso em `true` para sempre, e com ele a grade travada, só destravando se o
    /// usuário abrisse outro livro (que reatribui `isFlying` na marra). Corre em paralelo
    /// com a `completion` de verdade; o `flightID` garante que só uma das duas mexe em
    /// algo, e se a `completion` já tiver rodado isto é apenas um no-op.
    private func endFlightIfStuck(_ flight: Int, clearsFlyingBook: Bool) {
        Task {
            try? await Task.sleep(for: .seconds(Motion.heroFlightSettleTime))
            guard flight == flightID, isFlying else { return }
            isFlying = false
            if clearsFlyingBook { flyingBook = nil }
        }
    }

    /// O detalhe diz onde reservou o lugar da capa. Durante o voo isso vale uma mola;
    /// depois dele são só os pixels do scroll, e animar aí deixaria a capa a arrastar-se.
    private func place(_ placement: HeroPlacement) {
        guard isFlying else {
            heroPlacement = placement
            return
        }
        let flight = flightID
        withAnimation(Motion.heroFlight) {
            heroPlacement = placement
        } completion: {
            guard flight == flightID else { return }
            isFlying = false
        }
        endFlightIfStuck(flight, clearsFlyingBook: false)
    }

    // MARK: - Grade

    private var grid: some View {
        ScrollView {
            Group {
                if books.isEmpty {
                    emptyState
                } else if visibleBooks.isEmpty {
                    // Busca sem resultado nenhum (mesmo sem o filtro de status): oferece
                    // adicionar o livro. Se o filtro de status é que esconde tudo (o livro
                    // está na estante, só não nesta), o "nenhum resultado" genérico basta.
                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty && filteredBooks.isEmpty {
                        notFoundState
                    } else {
                        noResultsState
                    }
                } else {
                    gridContent
                }
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.top, chromeHeight)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollIndicators(.never)
        // Com o detalhe aberto ou o voo (de ida ou de volta) em curso, a grade continua
        // montada por baixo; rolá-la moveria as capas explodidas e a origem do voo. Sem
        // o `isFlying`, o fecho reativava o scroll antes da capa terminar de recuar —
        // ela ficava presa em tela por não acompanhar o offset do `ScrollView`.
        .scrollDisabled(selectedBook != nil || isFlying)
    }

    private var gridContent: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: Spacing.lg), GridItem(.flexible(), spacing: Spacing.lg)],
            spacing: Spacing.lg
        ) {
            ForEach(Array(visibleBooks.enumerated()), id: \.element.id) { index, book in
                Button {
                    select(book)
                } label: {
                    GridCover(
                        book: book,
                        width: columnWidth,
                        showsStatus: statusFilter == nil,
                        frameStore: frameStore,
                        isRecording: selectedBook == nil,
                        isFlying: flyingBook?.id == book.id
                    )
                }
                .buttonStyle(.plain)
                // Capas a direito: a explosão é o único movimento da grade.
                .scaleEffect(explodes(book) ? 1.35 : 1)
                .offset(explodeOffset(index: index))
                .opacity(explodes(book) ? 0 : 1)
                .zIndex(selectedBook == book ? 1 : 0)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            gridWidth = width
        }
    }

    private func explodes(_ book: Book) -> Bool {
        selectedBook != nil && selectedBook != book
    }

    /// Empurra cada capa não selecionada radialmente para longe da célula tocada.
    private func explodeOffset(index: Int) -> CGSize {
        guard let selected = selectedBook,
              let source = visibleBooks.firstIndex(of: selected),
              source != index
        else { return .zero }

        let column = index % 2, row = index / 2
        let sourceColumn = source % 2, sourceRow = source / 2
        var dx = Double(column - sourceColumn)
        let dy = Double(row - sourceRow)
        // Mesma coluna: empurra na mesma para fora, senão a capa só se afastaria na vertical.
        if dx == 0 { dx = column == 0 ? -0.5 : 0.5 }
        let length = max(hypot(dx, dy), 0.001)
        return CGSize(width: dx / length * 200, height: dy / length * 260)
    }

    // MARK: - Chrome fixo

    /// Título, busca e o rail de status, sobre um material que se dissolve para baixo —
    /// as capas passam por baixo dele em vez de colidirem com ele.
    private var topChrome: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            header
                .padding(.horizontal, Spacing.gutterList)

            searchField
                .padding(.horizontal, Spacing.gutterList)

            statusRail
        }
        .padding(.top, Spacing.cardInset)
        .padding(.bottom, Spacing.lg)
        .background(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [Palette.surface.opacity(0.8), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.42),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // A cauda do esmaecido derrama para além dos chips.
                .padding(.bottom, -95)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            chromeHeight = height
        }
    }

    /// Título e o "+" em ink. Figma `41:1019`. Com filtro, o título é o do status.
    private var header: some View {
        HStack {
            Text(statusFilter?.displayName ?? Localization.Library.title.string)
                .textStyle(.titleScreenLarge)
                .foregroundStyle(Palette.ink)

            Spacer()

            Button {
                isShowingAddOptions = true
            } label: {
                Image(systemName: "plus")
                    .font(.iconLabel)
                    .foregroundStyle(Palette.onBrand)
                    .frame(width: Spacing.addCircle, height: Spacing.addCircle)
                    .background(Circle().fill(Palette.brand))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.BookDetails.addToLibrary.string)
            // O modal cresce a partir do próprio "+", em vez de subir do rodapé.
            .matchedTransitionSource(id: "addBook", in: addButtonNamespace)
        }
    }

    /// Pílula de busca do design, no lugar do `.searchable` do sistema. Figma `41:1023`.
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.iconLabel)
                .foregroundStyle(Palette.inkFaint)

            TextField(
                "",
                text: $searchText,
                prompt: Text(Localization.Library.searchPrompt.string)
                    .foregroundColor(Palette.inkFaint)
            )
            .textStyle(.bodySupporting)
            .foregroundStyle(Palette.ink)
            .submitLabel(.search)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(Capsule().fill(Palette.surfaceRaised))
    }

    // MARK: - Filtro por status

    /// As prateleiras viraram um rail de pílulas — mesma linguagem de cápsula do resto.
    private var statusRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.sm) {
                chip(nil, Localization.Library.filterAll.string, filteredBooks.count)
                ForEach(shelfOrder, id: \.self) { status in
                    chip(status, status.displayName, filteredBooks.count { $0.status == status })
                }
            }
            .padding(.horizontal, Spacing.gutterList)
        }
        .scrollIndicators(.never)
        .scrollClipDisabled()
    }

    private func chip(_ status: BookStatus?, _ label: String, _ count: Int) -> some View {
        let isOn = statusFilter == status

        return Button {
            withAnimation(Motion.fast) { statusFilter = status }
        } label: {
            HStack(spacing: 6) {
                if let status {
                    Circle()
                        .fill(isOn ? Palette.onBrand : status.tint)
                        .frame(width: 7, height: 7)
                }

                Text(label)
                    .textStyle(.label)

                Text(verbatim: "\(count)")
                    .textStyle(.captionFine)
                    .foregroundStyle(isOn ? Palette.onBrand.opacity(0.6) : Palette.inkMeta)
            }
            .foregroundStyle(isOn ? Palette.onBrand : Palette.ink)
            .padding(.horizontal, Spacing.cardInset)
            .frame(height: 36)
            .background(isOn ? Palette.ink : Palette.surfaceRaised, in: .capsule)
            .overlay(Capsule().stroke(Palette.border, lineWidth: isOn ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Modal de adicionar livro

    private var addOptionsSheet: some View {
        VStack(spacing: Spacing.md) {
            Text(Localization.BookDetails.addToLibrary.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, Spacing.xs)

            addOptionRow(Localization.Library.scan.string, icon: "barcode.viewfinder", option: .scan)
            addOptionRow(Localization.Library.searchOption.string, icon: "magnifyingglass", option: .search)
            addOptionRow(Localization.Library.addManually.string, icon: "square.and.pencil", option: .manual)

            Spacer()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Sem cor de fundo opaca: o vidro do sistema deixa a biblioteca aparecer atrás,
        // que é o que dá a leitura de "camada por cima" em vez de tela preta nova.
        .presentationBackground(.regularMaterial)
        .presentationDetents([.height(340)])
        .presentationCornerRadius(Radius.sheet)
        .presentationDragIndicator(.visible)
    }

    private func addOptionRow(_ title: String, icon: String, option: AddOption) -> some View {
        Button {
            pendingOption = option
            isShowingAddOptions = false
        } label: {
            HStack(spacing: Spacing.cardInset) {
                Image(systemName: icon)
                    .font(.iconInline)
                    .foregroundStyle(Palette.ink)
                    .frame(width: 28)

                Text(title)
                    .textStyle(.field)
                    .foregroundStyle(Palette.ink)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }

    private func openPendingOption() {
        switch pendingOption {
        case .scan: isShowingScanner = true
        case .search: isShowingSearch = true
        case .manual: isShowingAddManually = true
        case nil: break
        }
        pendingOption = nil
    }

    private var noResultsState: some View {
        VStack(spacing: Spacing.cardInset) {
            Text(Localization.Library.noResultsTitle.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)

            Text(Localization.Library.noResultsSubtitle.string)
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    /// Busca sem nenhum resultado na estante: oferece adicionar o livro pelo modal padrão.
    private var notFoundState: some View {
        VStack(spacing: Spacing.cardInset) {
            Text(Localization.Library.notFoundTitle.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)

            Text(String(format: Localization.Library.notFoundMessage.string, searchText.trimmingCharacters(in: .whitespaces)))
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)

            ReadUpButton(title: Localization.Library.notFoundAction.string, variant: .primary) {
                isShowingAddOptions = true
            }
            .padding(.top, Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.cardInset) {
            Image(systemName: "books.vertical")
                .font(.iconSection)
                .foregroundStyle(Palette.inkFainter)

            Text(Localization.Library.emptyTitle.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)

            Text(Localization.Library.emptySubtitle.string)
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

#Preview {
    NavigationStack {
        Library()
            .environment(LibraryStore())
    }
}
