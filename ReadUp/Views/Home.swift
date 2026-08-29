//
//  Home.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI

struct Home: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(LibraryStore.self) private var store
    @State private var viewModel = HomeViewModel()
    @State private var isShowingAlert = false
    @State private var activeReadingBook: Book?
    @State private var selectedSession: LiterarySession?
    @State private var selectedUpNextBook: Book?

    private var books: [Book] { store.books }
    private var sessions: [LiterarySession] { store.sessions }

    private var sessionsCount: Int {
        sessions.count
    }
    
    private var readingBooks: [Book]{
        books.filter {
            $0.status == .reading
        }
    }
    
    private var upNextBooks: [Book] {
        books.filter { $0.status == .iWantToRead || $0.status == .rereading }
    }

    /// Capa em cache para um livro (se já baixada pela `LibraryStore`).
    private func coverData(for book: Book) -> Data? {
        guard let url = book.coverUrl else { return nil }
        return store.coverCache[url]
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                currentlyReadingSection
                    .padding(.top, Spacing.sm)
                
                HStack(spacing: Spacing.md) {
                    MetricCard(value: "\(viewModel.currentSessionStreak(from: sessions))", title: Localization.Home.metricDayStreak.string, icon: "flame.fill", accentColor: .orange)
                    MetricCard(value: viewModel.averageTimePerDayFormatted(from: sessions), title: Localization.Home.metricAverageTime.string, icon: "clock.fill", accentColor: .indigo)
                }
                
        
                
                Text(Localization.Home.recentActivity.string)
                    .font(.titleSecondary)
                
                if sessions.isEmpty {
                    HistoryEmptyState()
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(sessions.prefix(4).enumerated()), id: \.element.id) { index, session in
                            RecentActivityRow(session: session, formattedDate: viewModel.activityDate(session.timesTamp))
                                .onTapGesture {
                                    selectedSession = session
                                }
                            
                            if index < min(sessions.count, 4) - 1 {
                                Divider()
                                    .padding(.leading, 66)
                            }
                        }
                    }
                    .cardSurface(radius: Radius.lg)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle(viewModel.greetingText(name: authManager.currentUser?.name))
        .navigationBarTitleDisplayMode(.inline)
        .background(.surface)
        // A chave inclui a coverUrl: trocando a capa de um livro que já estava aqui, a
        // lista de ids não muda e a task não reexecutava — a capa antiga ficava na tela.
        .task(id: readingBooks.map { "\($0.id):\($0.coverUrl ?? "")" }) {
            await store.ensureReadingCovers()
        }
        .navigationDestination(item: $activeReadingBook) { book in
            ReadingSession(selectedBook: book, activeReadingBook: $activeReadingBook)
        }
        .navigationDestination(item: $selectedSession) { session in
            SessionSummary(readingTime: session.timeRead, currentBook: session.book, pagesRead: session.pagesRead, previousProgress: 0, sessionToEdit: session)
        }
        .navigationDestination(item: $selectedUpNextBook) { book in
            BookDetails(book: book)
        }
        .alert(Localization.Home.alertNoBooksTitle.string, isPresented: $isShowingAlert) {
            Button(Localization.Generic.ok.string) {}
        } message: {
            Text(Localization.Home.alertNoBooksMessage.string)
        }
    }
    
    private var currentlyReadingSection: some View {
        Group {
            if readingBooks.isEmpty {
                VStack(spacing: Spacing.cardInset) {
                    Image(systemName: "book.closed")
                        .font(.iconSection)
                        .foregroundStyle(.brand)
                    
                    Text(Localization.Home.emptyTitle.string)
                        .font(.titleSecondary)
                    
                    Text(Localization.Home.emptySubtitle.string)
                        .font(.bodyDefault)
                        .foregroundStyle(.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxl)
                
            } else if readingBooks.count == 1 {
                HStack(spacing: Spacing.md) {
                    Spacer()
                    ForEach(readingBooks) { book in
                        CurrentlyReadingCard(book: book, progressValue: viewModel.progressValue(for: book), coverData: coverData(for: book), onStartReading: {
                            activeReadingBook = book
                        })
                            .frame(width: 320)
                    }
                    Spacer()
                }
            } else {
                ScrollView(.horizontal) {
                    HStack{
                        ForEach(readingBooks) { book in
                            CurrentlyReadingCard(book: book, progressValue: viewModel.progressValue(for: book), coverData: coverData(for: book), onStartReading: {
                                activeReadingBook = book
                            })
                                .frame(width: 320)
                        }
                    }
                }
                .scrollIndicators(.never)
            }
        }
    }
    


    private var upNextSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(upNextBooks.prefix(8)) { book in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        BookCoverView(coverUrl: book.coverUrl, width: 120, height: 172)
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(book.author)
                            .font(.bodySupporting)
                            .foregroundStyle(.inkMuted)
                            .lineLimit(1)
                    }
                    .frame(width: 132, alignment: .leading)
                    .onTapGesture {
                        selectedUpNextBook = book
                    }
                }
                
                NavigationLink(destination: Library()) {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 38, weight: .regular))
                            .foregroundStyle(.brand)
                        Text(Localization.Home.addBook.string)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.brand)
                    }
                    .frame(width: 132, height: 230)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                            .fill(Color.brand.opacity(0.12))
                    )
                }
            }
        }
    }
    

}

#Preview {
    TabBar()
        .environment(AuthManager())
        .environment(LibraryStore())
}
