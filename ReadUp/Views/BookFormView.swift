import PhotosUI
import SwiftUI

/// Um formulário, dois modos: cadastro manual (vazio) e edição (pré-preenchido).
/// Ver `.claude/specs/2026-08-05-book-search-and-entry-design.md`.
struct BookFormView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: BookFormViewModel
    let onSaved: () -> Void

    init(mode: BookFormViewModel.Mode, onSaved: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: BookFormViewModel(mode: mode))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        coverPicker
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section {
                    TextField(Localization.AddBook.titlePlaceholder.string, text: $viewModel.title)
                    TextField(Localization.AddBook.authorPlaceholder.string, text: $viewModel.author)
                    TextField(Localization.AddBook.pagesPlaceholder.string, text: $viewModel.pagesText)
                        .keyboardType(.numberPad)
                    TextField(Localization.AddBook.isbnPlaceholder.string, text: $viewModel.isbn)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section {
                    Picker(Localization.AddBook.selectStatus.string, selection: $viewModel.status) {
                        ForEach(BookStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                Section {
                    TextEditor(text: $viewModel.details)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if viewModel.details.isEmpty {
                                Text(Localization.AddBook.detailsPlaceholder.string)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
            .navigationTitle(Localization.AddBook.saveBook.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Localization.Generic.cancel.string)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel.save(store: store) {
                                onSaved()
                                dismiss()
                            }
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(Localization.AddBook.saveBook.string)
                    .disabled(!viewModel.isSaveEnabled || viewModel.isSaving)
                }
            }
            .onChange(of: viewModel.selectedPhoto) { _, item in
                Task { await viewModel.handlePhotoSelection(item) }
            }
        }
    }

    @ViewBuilder
    private var coverPicker: some View {
        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images, photoLibrary: .shared()) {
            ZStack(alignment: .bottomTrailing) {
                if let image = viewModel.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 171)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else if let existingUrl = viewModel.mode.book?.coverUrl {
                    BookCoverView(coverUrl: existingUrl, width: 120, height: 171, cornerRadius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                        .frame(width: 120, height: 171)
                        .overlay {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                }
                Image(systemName: "camera.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(Color.emphasis))
                    .offset(x: 4, y: 4)
            }
        }
        .disabled(viewModel.isSaving)
    }
}

#Preview {
    BookFormView(mode: .create)
        .environment(LibraryStore())
}
