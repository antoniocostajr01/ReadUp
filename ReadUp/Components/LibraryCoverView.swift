import SwiftUI

struct LibraryCoverView: View {
    let book: Book

    var body: some View {
        CoverImage(url: book.coverUrl.flatMap(URL.init(string:))) { Color.surfaceFill }
            .frame(width: 44, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .stroke(Color.divider, lineWidth: 0.5)
            )
    }
}
