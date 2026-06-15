import SwiftUI

/// Capa de livro carregada por URL (backend devolve `coverUrl`).
struct BookCoverView: View {
    let coverUrl: String?
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = 10

    var body: some View {
        AsyncImage(url: coverUrl.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemFill))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
