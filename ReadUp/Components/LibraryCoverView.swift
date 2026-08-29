import SwiftUI

struct LibraryCoverView: View {
    let book: Book

    var body: some View {
        AsyncImage(url: book.coverUrl.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Color.surfaceFill
            }
        }
        .frame(width: 44, height: 62)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .stroke(Color.divider, lineWidth: 0.5)
        )
    }
}
