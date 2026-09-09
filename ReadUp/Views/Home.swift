//
//  Home.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

/// A aba Home. Figma `70:387` (seção "New home with history").
///
/// A saudação é conteúdo, não `navigationTitle`: no Figma ela é serifada de 34pt,
/// alinhada à esquerda, e rola junto com a página.
///
/// Todo livro em andamento fica alcançável: o herói virou um carrossel horizontal, e o
/// botão primário age sobre o card visível — não sobre o primeiro da lista.
struct Home: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(LibraryStore.self) private var store
    @State private var viewModel = HomeViewModel()
    @State private var activeReadingBook: Book?
    @State private var selectedSession: LiterarySession?
    /// Qual card do carrossel está na tela. Dirige a rolagem e o alvo do botão.
    @State private var activeBookID: String?
    /// Largura do carrossel, medida em tempo de layout — é dela que sai a margem que
    /// mantém o card ativo no centro da tela.
    @State private var carouselWidth: CGFloat = 0

    private var books: [Book] { store.books }
    private var sessions: [LiterarySession] { store.sessions }
    private var readingBooks: [Book] { books.filter { $0.status == .reading } }

    /// O livro sobre o qual o botão primário age: o do card visível, com o primeiro
    /// como rede de segurança enquanto a rolagem ainda não reportou nada.
    private var focusedBook: Book? {
        readingBooks.first { $0.id == activeBookID } ?? readingBooks.first
    }

    var body: some View {
        ScrollView {
            // Sem padding horizontal aqui: o carrossel sangra de borda a borda e cada
            // seção põe a sua própria goteira. Mesmo padrão do `statusRail` da Library.
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(viewModel.greetingText(name: authManager.currentUser?.name))
                    .textStyle(.titleScreen)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.gutterList)

                if readingBooks.isEmpty {
                    emptyHero
                        .padding(.horizontal, Spacing.gutterList)
                } else {
                    continueReading
                }

                stats
                    .padding(.horizontal, Spacing.gutterList)

                recentActivity
                    .padding(.horizontal, Spacing.gutterList)
            }
            .padding(.top, Spacing.cardInset)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Palette.surface)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { syncActiveBook() }
        .onChange(of: readingBooks.map(\.id)) { _, _ in syncActiveBook() }
        .navigationDestination(item: $activeReadingBook) { book in
            ReadingSession(selectedBook: book, activeReadingBook: $activeReadingBook)
        }
        .navigationDestination(item: $selectedSession) { session in
            SessionSummary(
                readingTime: session.timeRead,
                currentBook: session.book,
                pagesRead: session.pagesRead,
                previousProgress: 0,
                sessionToEdit: session
            )
        }
    }

    /// Mantém `activeBookID` apontando para um livro que ainda existe — a biblioteca
    /// recarrega, um livro sai de "lendo", e o id guardado viraria um ponteiro morto.
    private func syncActiveBook() {
        guard !readingBooks.isEmpty else {
            activeBookID = nil
            return
        }
        if activeBookID == nil || !readingBooks.contains(where: { $0.id == activeBookID }) {
            activeBookID = readingBooks.first?.id
        }
    }

    // MARK: - Continuar lendo

    /// Rótulo, carrossel, indicador e ação. Figma `70:410` … `70:434`.
    @ViewBuilder
    private var continueReading: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(sectionLabel)
                .textStyle(.overline)
                .foregroundStyle(Palette.inkFaint)
                .padding(.horizontal, Spacing.gutterList)

            carousel

            if readingBooks.count > 1 {
                // Centralizado como o card que ele acompanha.
                pageIndicator
                    .frame(maxWidth: .infinity)
            }

            if let focusedBook {
                ReadUpButton(
                    title: (focusedBook.progress ?? 0) == 0
                        ? Localization.Components.startReading.string
                        : Localization.Components.continueReading.string
                ) {
                    activeReadingBook = focusedBook
                }
                .padding(.horizontal, Spacing.gutterList)
            }
        }
    }

    private var sectionLabel: String {
        readingBooks.count > 1
            ? String(format: Localization.Home.continueReadingSectionCount.string, readingBooks.count)
                .uppercased()
            : Localization.Home.continueReadingSection.string.uppercased()
    }

    /// O card ativo fica sempre no centro da tela, com os vizinhos espiando dos dois
    /// lados. A margem lateral é metade da sobra ao lado de um card: sem ela o primeiro
    /// e o último não teriam para onde rolar para alcançar o meio, e encostariam na
    /// borda em vez de centralizar.
    private var carousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Spacing.cardInset) {
                ForEach(readingBooks) { book in
                    CurrentlyReadingCard(
                        book: book,
                        progressValue: viewModel.progressValue(for: book),
                        width: Spacing.readingCardWidth,
                        height: Spacing.readingCardHeight
                    )
                    .id(book.id)
                    // A capa é o alvo óbvio: tocar nela abre a sessão do livro
                    // tocado, mesmo que não seja o card centralizado.
                    .contentShape(.rect)
                    .onTapGesture { activeReadingBook = book }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, sideMargin, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $activeBookID, anchor: .center)
        .scrollIndicators(.never)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            carouselWidth = width
        }
    }

    private var sideMargin: CGFloat {
        max(Spacing.gutterList, (carouselWidth - Spacing.readingCardWidth) / 2)
    }

    /// O card ativo vira um traço; os outros ficam pontos. Figma `70:430`.
    private var pageIndicator: some View {
        HStack(spacing: Spacing.sm - 2) {
            ForEach(readingBooks) { book in
                let isActive = book.id == activeBookID
                Capsule()
                    .fill(isActive ? Palette.ink : Palette.ink.opacity(0.22))
                    .frame(width: isActive ? 16 : 6, height: 6)
            }
        }
        .animation(Motion.fast, value: activeBookID)
        .accessibilityHidden(true)
    }

    /// Sem nada em andamento o herói não existe — no lugar dele, o convite.
    private var emptyHero: some View {
        VStack(spacing: Spacing.cardInset) {
            Image(systemName: "book.closed")
                .font(.iconSection)
                .foregroundStyle(Palette.inkFainter)

            Text(Localization.Home.emptyTitle.string)
                .textStyle(.titleSecondary)
                .foregroundStyle(Palette.ink)

            Text(Localization.Home.emptySubtitle.string)
                .textStyle(.bodySupporting)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Métricas

    /// Três métricas num card só, separadas por régua. Figma `70:439`.
    ///
    /// Eram dois quadros soltos de tamanhos diferentes; viraram um instrumento — mesma
    /// linha de base, mesmo peso, comparáveis de relance.
    private var stats: some View {
        let streak = viewModel.currentSessionStreak(from: sessions)
        let minutes = viewModel.averageMinutesPerDay(from: sessions)
        let pages = viewModel.pagesThisWeek(from: sessions)

        return HStack(spacing: 0) {
            StatColumn(
                label: Localization.Home.metricDayStreak.string,
                value: "\(streak)",
                unit: Localization.Components.days(streak)
            )

            statDivider

            StatColumn(
                label: Localization.Home.metricAverageTime.string,
                value: "\(minutes)",
                unit: Localization.Components.unitMinutes.string
            )

            statDivider

            StatColumn(
                label: Localization.Home.metricThisWeek.string,
                value: "\(pages)",
                unit: Localization.Components.pages(pages)
            )
        }
        .padding(.vertical, Spacing.lg)
        .frame(maxWidth: .infinity)
        .cardSurface(radius: Radius.card)
    }

    /// `Divider` é a régua de uma lista; entre colunas de métrica o que se quer é um
    /// traço de 1pt com altura própria.
    private var statDivider: some View {
        Rectangle()
            .fill(Palette.divider)
            .frame(width: 1, height: 48)
    }

    // MARK: - Atividade recente

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(Localization.Home.recentActivity.string)
                    .textStyle(.titleSecondary)
                    .foregroundStyle(Palette.ink)

                Spacer()

                if !sessions.isEmpty {
                    NavigationLink {
                        History()
                    } label: {
                        Text(Localization.Home.seeAll.string)
                            .textStyle(.label)
                            .foregroundStyle(Palette.inkMeta)
                    }
                }
            }

            if sessions.isEmpty {
                HistoryEmptyState()
            } else {
                VStack(spacing: 0) {
                    ForEach(sessions.prefix(4)) { session in
                        RecentActivityRow(
                            session: session,
                            formattedDate: viewModel.activityDate(session.timesTamp)
                        )
                        .contentShape(.rect)
                        .onTapGesture { selectedSession = session }

                        Divider().overlay(Palette.divider)
                    }
                }
            }
        }
    }
}

// MARK: - Coluna de métrica

/// Rótulo em caixa alta, número serifado e a unidade em sans. Figma `70:440`.
private struct StatColumn: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: Spacing.sm - 2) {
            Text(label.uppercased())
                .textStyle(.overline)
                .foregroundStyle(Palette.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(value)
                    .textStyle(.titlePrimary)
                    .foregroundStyle(Palette.ink)

                Text(unit)
                    .textStyle(.captionDefault)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TabBar()
        .environment(AuthManager())
        .environment(LibraryStore())
}
