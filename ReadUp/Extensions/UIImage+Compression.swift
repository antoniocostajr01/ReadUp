import UIKit

/// Redimensiona e comprime uma imagem para envio ao backend como base64 leve.
/// Usado pela foto de perfil e pela capa de livro cadastrada manualmente.
extension UIImage {
    func compressedBase64(maxDimension: CGFloat = 512, quality: CGFloat = 0.7) -> String? {
        let largestSide = max(size.width, size.height)
        let scale = largestSide > maxDimension ? maxDimension / largestSide : 1
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        guard let jpeg = resized.jpegData(compressionQuality: quality) else { return nil }
        return jpeg.base64EncodedString()
    }
}
