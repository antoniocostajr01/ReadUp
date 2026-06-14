import Foundation

/// Configurações de ambiente lidas do Info.plist (alimentado pelo Secrets.xcconfig).
enum AppConfig {

    /// URL base do backend. Na main aponta para o servidor de produção (Render).
    /// Em desenvolvimento, troque o valor de BASEURL no Secrets.xcconfig para o localhost.
    static var baseURL: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "BASEURL") as? String,
              !value.isEmpty else {
            fatalError("BASEURL não foi encontrada no Info.plist")
        }
        return value
    }
}
