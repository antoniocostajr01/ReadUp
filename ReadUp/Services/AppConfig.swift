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

    #if DEBUG
    /// Conta de teste (`DEV_EMAIL` / `DEV_PASSWORD` no `Secrets.xcconfig`, que é
    /// gitignored). Existe só pra o build de debug não cair no modo convidado a cada
    /// reinstalação. Em Release as chaves vêm vazias, então isto é sempre `nil`.
    static var devCredentials: (email: String, password: String)? {
        guard let email = Bundle.main.object(forInfoDictionaryKey: "DEV_EMAIL") as? String,
              let password = Bundle.main.object(forInfoDictionaryKey: "DEV_PASSWORD") as? String,
              !email.isEmpty, !password.isEmpty else { return nil }
        return (email, password)
    }
    #endif
}
