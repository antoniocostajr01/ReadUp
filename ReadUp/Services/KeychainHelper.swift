import Foundation
import Security

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
            // Só acessível quando o device está desbloqueado, e não migra em backups.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Lê o valor de texto guardado sob uma chave (nil se não existir).
    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
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
}
