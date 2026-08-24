import Foundation

/// Extração e validação de ISBN. Existe porque o scanner agora lê duas fontes muito
/// diferentes: o código de barras (13 dígitos limpos) e o texto impresso/na tela, que
/// vem sujo — "ISBN-13 978-8539643226", junto de preço, telefone e o que mais estiver
/// em quadro. O dígito verificador é o que separa um ISBN de um número qualquer.
enum ISBN {

    /// Primeiro ISBN válido dentro de um texto reconhecido, ou `nil`.
    /// Procura o de 13 dígitos antes do de 10: quando os dois estão impressos lado a
    /// lado (caso comum em contracapa e em página de e-commerce), o de 13 é o atual.
    static func firstValid(in text: String) -> String? {
        for pattern in [isbn13Pattern, isbn10Pattern] {
            let candidates = matches(of: pattern, in: text).map(normalized)
            if let valid = candidates.first(where: isValid) {
                return valid
            }
        }
        return nil
    }

    /// Só dígitos e `X`, em maiúscula — o formato que o backend espera.
    static func normalized(_ raw: String) -> String {
        raw.filter { $0.isNumber || $0 == "X" || $0 == "x" }.uppercased()
    }

    static func isValid(_ isbn: String) -> Bool {
        switch isbn.count {
        case 13: return isValidIsbn13(isbn)
        case 10: return isValidIsbn10(isbn)
        default: return false
        }
    }

    // MARK: - Privado

    // Hífen e espaço opcionais entre os dígitos: a impressão usa hífen, o OCR às vezes
    // devolve espaço, e o código de barras não usa separador nenhum.
    private static let isbn13Pattern = #"97[89](?:[- ]?\d){10}"#
    private static let isbn10Pattern = #"(?<!\d)\d(?:[- ]?\d){8}[- ]?[\dXx](?!\d)"#

    private static func matches(of pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }

    /// Soma com pesos 1 e 3 alternados, múltiplo de 10.
    private static func isValidIsbn13(_ isbn: String) -> Bool {
        let digits = isbn.compactMap { $0.wholeNumberValue }
        guard digits.count == 13 else { return false }
        let sum = digits.enumerated().reduce(0) { total, item in
            total + item.element * (item.offset % 2 == 0 ? 1 : 3)
        }
        return sum % 10 == 0
    }

    /// Soma com pesos 10..1, múltiplo de 11; o último dígito pode ser `X` (= 10).
    private static func isValidIsbn10(_ isbn: String) -> Bool {
        let characters = Array(isbn)
        guard characters.count == 10 else { return false }

        var sum = 0
        for (index, character) in characters.enumerated() {
            let value: Int
            if character == "X" {
                guard index == 9 else { return false }
                value = 10
            } else {
                guard let digit = character.wholeNumberValue else { return false }
                value = digit
            }
            sum += value * (10 - index)
        }
        return sum % 11 == 0
    }
}
