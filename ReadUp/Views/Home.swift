//
//  Home.swift
//  ReadUp
//
//  Created by Antonio Costa on 06/08/25.
//

import SwiftUI
import SwiftData

struct Home: View {
    @State private var viewModel = HomeViewModel()
    @State private var isShowingAlert = false
    @State private var activeReadingBook: Book?
    @State private var selectedSession: LiterarySession?
    @State private var selectedUpNextBook: Book?
    
    @Query var books: [Book]
    
    @Query(sort: \LiterarySession.timesTamp, order: .reverse) var sessions: [LiterarySession]
    
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                currentlyReadingSection
                    .padding(.top, 8)
                
                HStack(spacing: 12) {
                    MetricCard(value: "\(viewModel.currentSessionStreak(from: sessions))", title: "DAY STREAK", icon: "flame.fill", accentColor: .orange)
                    MetricCard(value: "\(viewModel.averageMinutesPerDay(from: sessions))", title: "AVERAGE TIME", icon: "clock.fill", accentColor: .indigo)
                }
                
        
                
                Text("Recent Activity")
                    .font(.system(.title2, weight: .bold))
                
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
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle(viewModel.greetingText)
        .background(.backgroundPrimary)
        .navigationDestination(item: $activeReadingBook) { book in
            ReadingSession(selectedBook: book, activeReadingBook: $activeReadingBook)
        }
        .navigationDestination(item: $selectedSession) { session in
            SessionSummary(readingTime: session.timeRead, currentBook: session.book, pagesRead: session.pagesRead, previousProgress: 0, sessionToEdit: session)
        }
        .navigationDestination(item: $selectedUpNextBook) { book in
            BookDetails(book: book)
        }
        .alert("No Books Found" ,isPresented: $isShowingAlert) {
            Button("Ok") {}
        } message: {
            Text("You aren't reading any book. Please add some book with 'Reading' status to your library.")
        }
    }
    
    private var currentlyReadingSection: some View {
        Group {
            if readingBooks.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(.emphasis)
                    
                    Text("No book in progress")
                        .font(.system(.title2, weight: .bold))
                    
                    Text("Add a book as Reading and start your next session.")
                        .font(.body)
                        .foregroundStyle(.secundaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                
            } else if readingBooks.count == 1 {
                HStack(spacing: 12) {
                    Spacer()
                    ForEach(readingBooks) { book in
                        CurrentlyReadingCard(book: book, progressValue: viewModel.progressValue(for: book), onStartReading: {
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
                            CurrentlyReadingCard(book: book, progressValue: viewModel.progressValue(for: book), onStartReading: {
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
            HStack(spacing: 12) {
                ForEach(upNextBooks.prefix(8)) { book in
                    VStack(alignment: .leading, spacing: 8) {
                        BookCoverView(data: book.imageData, width: 120, height: 172)
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(.secundaryLabel)
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
                            .foregroundStyle(.emphasis)
                        Text("Add Book")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.emphasis)
                    }
                    .frame(width: 132, height: 230)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.emphasis.opacity(0.12))
                    )
                }
            }
        }
    }
    

}

#Preview {
    TabBar()
        .environment(AuthManager())
}
