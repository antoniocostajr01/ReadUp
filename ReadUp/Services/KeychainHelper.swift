import Foundation
import Security

/// O que uma leitura do Keychain encontrou. "Bloqueado" não é "vazio": antes do primeiro
/// desbloqueio (o iOS pode pré-aquecer o app com o aparelho travado) o item existe mas
/// não pode ser lido, e tratar isso como "sem token" deslogava o usuário.
enum KeychainReadResult {
    case value(String)
    case notFound
    case locked
}

/// Wrapper simples sobre o Keychain do iOS para guardar credenciais com segurança.
/// O Keychain é criptografado pelo sistema — diferente do UserDefaults, que é texto plano.
enum KeychainHelper {

    /// Salva (ou atualiza) um valor de texto sob uma chave.
    @discardableResult
    static func save(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Remove qualquer item anterior com a mesma chave antes de inserir.
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Legível depois do primeiro desbloqueio desde o boot — inclusive com a tela
            // travada, que é quando a Live Activity e o pré-aquecimento acordam o app.
            // Não migra em backups.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Lê o valor de texto guardado sob uma chave (nil se não existir ou não puder ser lido).
    static func read(_ key: String) -> String? {
        if case .value(let value) = readResult(key) { return value }
        return nil
    }

    /// Lê distinguindo "não existe" de "existe, mas o aparelho está bloqueado".
    static func readResult(_ key: String) -> KeychainReadResult {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
                return .notFound
            }
            return .value(value)
        case errSecInteractionNotAllowed:
            return .locked
        default:
            return .notFound
        }
    }

    /// Remove o valor guardado sob uma chave.
    @discardableResult
    static func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

/// Chaves usadas no Keychain.
enum KeychainKey {
    static let authToken = "readup.authToken"
    static let refreshToken = "readup.refreshToken"
}
