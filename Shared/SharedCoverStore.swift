//
//  SharedCoverStore.swift
//  ReadUp
//

import UIKit

/// A ponte da capa entre o app e a extensão.
///
/// A Live Activity é desenhada em outro processo e não baixa `coverUrl` — nem
/// `AsyncImage` nem `URLSession` funcionam lá dentro. Então o app grava a capa da
/// sessão corrente no container do App Group e a extensão lê o arquivo.
///
/// Um arquivo só, sobrescrito a cada sessão: só existe uma sessão por vez, e um
/// diretório por livro viraria lixo que ninguém limpa.
enum SharedCoverStore {

    static let appGroup = "group.com.antoniocosta.ReadUpApp"

    /// O card desenha a capa a 61×88pt; 3× cobre o maior scale de tela.
    private static let pixelSize = CGSize(width: 61 * 3, height: 88 * 3)

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("session-cover.jpg")
    }

    /// Grava a capa já no tamanho em que será desenhada. Sem o resize, uma capa de
    /// 1400px iria inteira para o disco e para a memória da extensão, que tem um
    /// orçamento bem menor que o do app.
    static func write(_ image: UIImage) {
        guard let fileURL else { return }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: pixelSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
        try? resized.jpegData(compressionQuality: 0.85)?.write(to: fileURL, options: .atomic)
    }

    static func read() -> UIImage? {
        guard let fileURL else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    /// Chamado quando a sessão acaba, e também quando o livro não tem capa — senão a
    /// sessão de hoje herdaria a capa da sessão de ontem.
    static func clear() {
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}
