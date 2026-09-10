//
//  History.swift
//  ReadUp
//
//  Created by Antonio Costa on 09/08/25.
//

import SwiftUI

/// O histórico de sessões. Figma `21:42` (seção "New home with history").
///
/// Chega por um push do "See all" do Home. O título é serifado de 38pt e rola junto
/// com a página — conteúdo, não `navigationTitle`, que não sabe desenhar a fonte do
/// app. Com a barra de navegação escondida, o retorno é um `ChromeChip` próprio: o
/// Figma não desenha nenhum, e uma tela empurrada alcançável só pelo gesto de borda
/// não é aceitável.
struct History: View {

    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = HomeViewModel()
    @State private var selectedSession: LiterarySession?

    private var sessions: [LiterarySession] { store.sessions }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header

                if sessions.isEmpty {
                    HistoryEmptyState()
                } else {
                    WeekBars(
                        minutes: viewModel.minutesByWeekday(from: sessions),
                        labels: viewModel.weekdayLabels()
                    )

                    let periods = viewModel.sessionsByPeriod(from: sessions)

                    section(Localization.History.sectionThisWeek.string, periods.thisWeek)
                    section(Localization.History.sectionEarlier.string, periods.earlier)
                }
            }
            .padding(.horizontal, Spacing.gutterList)
            .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedSession) { session in
            // O acumulado até esta sessão, não o delta dela: o card e a barra de
            // progresso falam do livro, não da sessão.
            let progress = store.cumulativeProgress(upTo: session)
            SessionSummary(
                readingTime: session.timeRead,
                currentBook: session.book,
                pagesRead: progress.total,
                previousProgress: progress.previous,
                session: session,
                mode: .reviewing
            )
        }
    }

    // MARK: - Cabeçalho

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            ChromeChip(systemImage: "chevron.left") { dismiss() }

            VStack(alignment: .leading, spacing: Spacing.sm - 2) {
                Text(Localization.History.title.string)
                    .textStyle(.titleScreenLarge)
                    .foregroundStyle(Palette.ink)

                if !sessions.isEmpty {
                    let totals = viewModel.historyTotals(from: sessions)
                    Text(
                        Localization.History.totals(
                            sessions: totals.count,
                            duration: viewModel.durationFormatted(seconds: totals.seconds),
                            pages: totals.pages
                        )
                    )
                    .textStyle(.bodySupporting)
                    .foregroundStyle(Palette.inkMeta)
                }
            }
        }
    }

    // MARK: - Seções

    /// Uma seção some inteira quando não tem sessão — sem cabeçalho órfão.
    @ViewBuilder
    private func section(_ title: String, _ items: [LiterarySession]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title.uppercased())
                    .textStyle(.overline)
                    .foregroundStyle(Palette.inkFaint)

                VStack(spacing: 0) {
                    ForEach(items) { session in
                        RecentActivityRow(
                            session: session,
                            formattedDate: viewModel.sessionMeta(session),
                            coverWidth: Spacing.coverHistoryWidth,
                            coverHeight: Spacing.coverHistoryHeight,
                            titleStyle: .headingRow,
                            showsPagesCaption: true
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

#Preview {
    NavigationStack {
        History()
            .environment(LibraryStore())
    }
}
