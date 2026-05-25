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
                    metricCard(value: "\(viewModel.currentSessionStreak(from: sessions))", title: "DAY STREAK", icon: "flame.fill", accentColor: .orange)
                    metricCard(value: "\(viewModel.averageMinutesPerDay(from: sessions))", title: "AVG. MIN / SESSION", icon: "clock.fill", accentColor: .indigo)
                }
                
        
                
                Text("Recent Activity")
                    .font(.system(.title2, weight: .bold))
                
                if sessions.isEmpty {
                    HistoryEmptyState()
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(sessions.prefix(4).enumerated()), id: \.element.id) { index, session in
                            recentActivityRow(session: session)
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
            SessionSummary(readingTime: session.timeRead, currentBook: session.book, pagesRead: session.pagesRead, sessionToEdit: session )
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
                HStack(alignment: .center){
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 10) {
                        Text("No book in progress")
                            .font(.headline)
                        Text("Add a book as Reading and start your next session.")
                            .font(.subheadline)
                            .foregroundStyle(.secundaryLabel)
                        Button("Start Reading") {
                            isShowingAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.emphasis)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    Spacer()
                }
                
            } else if readingBooks.count == 1 {
                HStack(spacing: 12) {
                    Spacer()
                    ForEach(readingBooks) { book in
                        currentlyReadingCard(for: book)
                            .frame(width: 320)
                    }
                    Spacer()
                }
            } else {
                ScrollView(.horizontal) {
                    HStack{
                        ForEach(readingBooks) { book in
                            currentlyReadingCard(for: book)
                                .frame(width: 320)
                        }
                    }
                }
                .scrollIndicators(.never)
            }
        }
    }
    
    private func currentlyReadingCard(for book: Book) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                coverView(data: book.imageData, width: 86, height: 124)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secundaryLabel)
                        .lineLimit(1)
                    Text(book.title)
                        .font(.system(.title3, weight: .bold))
                        .lineLimit(2)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secundaryLabel)
                        .lineLimit(1)
                    
                    let currentProgress = max(0, book.progress ?? 0)
                    let totalPages = max(1, book.numberOfPages)
                    let percentage = Int((Double(currentProgress) / Double(totalPages) * 100).rounded())
                    
                    HStack {
                        Text("Page \(currentProgress) of \(book.numberOfPages)")
                            .font(.subheadline)
                            .foregroundStyle(.secundaryLabel)
                        Spacer()
                        Text("\(min(percentage, 100))%")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(.emphasis)
                    }
                    .padding(.top, 4)
                }
            }
            
            ProgressView(value: viewModel.progressValue(for: book))
                .tint(.emphasis)
            
            Button {
                activeReadingBook = book
            } label: {
                Text((book.progress ?? 0) == 0 ? "Start Reading" : "Continue Reading")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.emphasis)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
    
    private func metricCard(value: String, title: String, icon: String, accentColor: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(accentColor)
                .padding(10)
            //                .background(Circle().fill(accentColor.opacity(0.15)))
            
            Text(value)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secundaryLabel)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
    
    private var upNextSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(upNextBooks.prefix(8)) { book in
                    VStack(alignment: .leading, spacing: 8) {
                        coverView(data: book.imageData, width: 120, height: 172)
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
    
    private func recentActivityRow(session: LiterarySession) -> some View {
        HStack(spacing: 12) {
            coverView(data: session.book.imageData, width: 40, height: 56)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.book.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(viewModel.activityDate(session.timesTamp))
                    .font(.subheadline)
                    .foregroundStyle(.secundaryLabel)
            }
            
            Spacer()
            
            Text("+\(session.pagesRead) pages")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.emphasis)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    

    
    @ViewBuilder
    private func coverView(data: Data, width: CGFloat, height: CGFloat) -> some View {
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: width, height: height)
        }
    }
}

#Preview {
    TabBar()
}
