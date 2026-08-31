//
//  Home.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

/// A aba Home. Figma `13:2` (seção "Tabs").
///
/// A saudação é conteúdo, não `navigationTitle`: no Figma ela é serifada de 34pt,
/// alinhada à esquerda, e rola junto com a página.
struct Home: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(LibraryStore.self) private var store
    @State private var viewModel = HomeViewModel()
    @State private var activeReadingBook: Book?
    @State private var selectedSession: LiterarySession?
    @State private var isShowingAddBook = false

    private var books: [Book] { store.books }
    private var sessions: [LiterarySession] { store.sessions }
    private var readingBooks: [Book] { books.filter { $0.status == .reading } }

    /// O livro do herói: o que está sendo lido agora. Com mais de um, o primeiro.
    private var heroBook: Book? { readingBooks.first }

    /// Capa em cache para um livro (se já baixada pela `LibraryStore`).
    private func coverData(for book: Book) -> Data? {
        guard let url = book.coverUrl else { return nil }
        return store.coverCache[url]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(viewModel.greetingText(name: authManager.currentUser?.name))
                    .textStyle(.titleScreen)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let heroBook {
                    CurrentlyReadingCard(
                        book: heroBook,
                        progressValue: viewModel.progressValue(for: heroBook),
                        coverData: coverData(for: heroBook)
                    )
                    actions(for: heroBook)
                } else {
                    emptyHero
                }

                stats
                recentActivity
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.top, Spacing.cardInset)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Palette.surface)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        // A chave inclui a coverUrl: trocando a capa de um livro que já estava aqui, a
        // lista de ids não muda e a task não reexecutava — a capa antiga ficava na tela.
        .task(id: readingBooks.map { "\($0.id):\($0.coverUrl ?? "")" }) {
            await store.ensureReadingCovers()
        }
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
        .navigationDestination(isPresented: $isShowingAddBook) { Search() }
    }

    // MARK: - Ações

    /// Botão primário + o círculo de adicionar. Figma `14:2`.
    private func actions(for book: Book) -> some View {
        HStack(spacing: Spacing.sm + 2) {
            ReadUpButton(
                title: (book.progress ?? 0) == 0
                    ? Localization.Components.startReading.string
                    : Localization.Components.continueReading.string
            ) {
                activeReadingBook = book
            }

            Button {
                isShowingAddBook = true
            } label: {
                Text(verbatim: "+")
                    .textStyle(.titleCard)
                    .foregroundStyle(Palette.ink)
                    .frame(width: Spacing.controlCircle, height: Spacing.controlCircle)
                    .background(Circle().fill(Palette.surfaceControl))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.Home.addBook.string)
        }
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

    /// Sequência e média diária. Figma `14:7`.
    private var stats: some View {
        HStack(spacing: Spacing.md) {
            StatTile(label: Localization.Home.metricDayStreak.string) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.iconSection)
                        .foregroundStyle(Palette.ink)
                    Text("\(viewModel.currentSessionStreak(from: sessions))")
                        .textStyle(.displayMetricXL)
                        .foregroundStyle(Palette.ink)
                }
                .frame(maxWidth: .infinity)
            }

            StatTile(label: Localization.Home.metricAverageTime.string) {
                Text(viewModel.averageTimePerDayFormatted(from: sessions))
                    .textStyle(.titleXL)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Stat tile

/// Um quadro de métrica: overline em caixa alta e o valor em serifada. Figma `14:8`.
private struct StatTile<Value: View>: View {
    let label: String
    @ViewBuilder let value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm - 2) {
            Text(label.uppercased())
                .textStyle(.overline)
                .foregroundStyle(Palette.inkFaint)

            value
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardSurface(radius: Radius.card)
    }
}

#Preview {
    TabBar()
        .environment(AuthManager())
        .environment(LibraryStore())
}
