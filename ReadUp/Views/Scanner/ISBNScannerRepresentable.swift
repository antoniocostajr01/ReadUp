import SwiftUI
import VisionKit

/// Ponte para o `DataScannerViewController` do VisionKit, configurado só pra código de
/// barras (EAN-13/EAN-8/UPC-E cobrem os formatos usados em livros).
struct ISBNScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Texto além do código de barras: em vitrine online (e em livro com código
        // apagado) o ISBN só aparece impresso. Quem separa um ISBN de um preço ou
        // telefone em quadro é o dígito verificador, em `ISBN.firstValid`.
        // Só EAN-13: livro usa Bookland, e EAN-8/UPC-E só entrariam como ruído.
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13]), .text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isPinchToZoomEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        // Reinicia só se por algum motivo parou (ex.: voltou de background) — chamar
        // startScanning todo update reinicia o tracking e derruba a câmera.
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            forward(addedItems)
        }

        /// O OCR refina o texto depois de reconhecê-lo: o `didAdd` costuma trazer o ISBN
        /// pela metade, e a leitura boa chega aqui. Sem isso, texto só funciona por sorte.
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            forward(updatedItems)
        }

        private func forward(_ items: [RecognizedItem]) {
            for item in items {
                switch item {
                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue { onScan(payload) }
                case .text(let text):
                    onScan(text.transcript)
                @unknown default:
                    continue
                }
            }
        }
    }
}
